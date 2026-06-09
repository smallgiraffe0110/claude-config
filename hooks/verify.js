#!/usr/bin/env node
// Claude Code verification hook — keeps TS/JS output compiling + lint-clean.
//
//   node verify.js lint       PostToolUse(Edit|Write|MultiEdit): eslint --fix the changed file
//   node verify.js typecheck  Stop: project-wide typecheck; blocks turn-end on type errors
//
// Bails (exit 0) instantly outside JS/TS projects, so it is free everywhere else.
// Feedback to Claude is via stderr + exit code 2; exit 0 means "all good, proceed".

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const mode = process.argv[2];

let input = {};
try { const raw = fs.readFileSync(0, 'utf8'); input = raw ? JSON.parse(raw) : {}; } catch { /* empty stdin */ }

const ok = () => process.exit(0);
const block = (msg) => { process.stderr.write(msg + '\n'); process.exit(2); };

// Nearest ancestor dir (inclusive) containing any marker file.
const findUp = (start, markers) => {
  let dir = start;
  for (;;) {
    if (markers.some(m => fs.existsSync(path.join(dir, m)))) return dir;
    const up = path.dirname(dir);
    if (up === dir) return null;
    dir = up;
  }
};

// Resolve a project-local CLI (node_modules/.bin/<name>), or null.
const bin = (root, name) => {
  const p = path.join(root, 'node_modules', '.bin', name);
  return fs.existsSync(p) ? p : null;
};

const JS_EXT = /\.(ts|tsx|mts|cts|js|jsx|mjs|cjs)$/;

if (mode === 'lint') {
  const ti = input.tool_input || {};
  const fp = ti.file_path || ti.filePath;
  if (!fp || !JS_EXT.test(fp) || !fs.existsSync(fp)) ok();
  const root = findUp(path.dirname(path.resolve(fp)), ['package.json']);
  if (!root) ok();
  const eslint = bin(root, 'eslint');
  if (!eslint) ok();                               // no local eslint -> skip
  const res = spawnSync(eslint, ['--fix', fp], { cwd: root, encoding: 'utf8', timeout: 60000 });
  if (res.status === 0 || res.status == null) ok(); // clean, or spawn/timeout error -> don't nag
  const out = ((res.stdout || '') + (res.stderr || '')).trim();
  if (!out) ok();
  block('eslint problems in ' + fp + ' (auto-fix applied where possible):\n' + out + '\nFix the remaining issues.');
}

if (mode === 'typecheck') {
  if (input.stop_hook_active) ok();                // loop guard: only block once per stop-chain
  const cwd = input.cwd || process.cwd();
  const root = findUp(path.resolve(cwd), ['tsconfig.json', 'package.json']);
  if (!root) ok();
  let pkg = {};
  try { pkg = JSON.parse(fs.readFileSync(path.join(root, 'package.json'), 'utf8')); } catch { /* no pkg */ }
  const hasTs = fs.existsSync(path.join(root, 'tsconfig.json'));
  const tsc = bin(root, 'tsc');
  let res;
  if (pkg.scripts && pkg.scripts.typecheck) {
    res = spawnSync('npm', ['run', '--silent', 'typecheck'], { cwd: root, encoding: 'utf8', timeout: 180000 });
  } else if (hasTs && tsc) {
    res = spawnSync(tsc, ['--noEmit'], { cwd: root, encoding: 'utf8', timeout: 180000 });
  } else {
    ok();                                          // not a typecheckable project
  }
  if (!res || res.status === 0 || res.status == null) ok(); // pass, or timeout -> allow stop
  const out = ((res.stdout || '') + (res.stderr || '')).trim();
  if (!out) ok();
  block('Typecheck failed in ' + root + ':\n' + out + '\nFix these type errors before finishing.');
}

ok();
