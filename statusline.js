#!/usr/bin/env node
// Claude Code status line — Max plan usage with style
const fs = require('fs');
const path = require('path');

const HOME = process.env.HOME || process.env.USERPROFILE;
const CACHE_PATH = path.join(HOME, '.claude', '.usage-cache.json');
const CREDS_PATH = path.join(HOME, '.claude', '.credentials.json');
const CACHE_TTL = 60_000;

// ANSI colors
const RST  = '\x1b[0m';
const BOLD = '\x1b[1m';
const DIM  = '\x1b[2m';
const ITALIC = '\x1b[3m';

// 256-color mode for richer palette
const fg = (n) => `\x1b[38;5;${n}m`;
const bg = (n) => `\x1b[48;5;${n}m`;

// Color palette
const PURPLE  = fg(141);  // soft purple
const BLUE    = fg(75);   // bright blue
const TEAL    = fg(43);   // teal/mint
const ORANGE  = fg(214);  // warm orange
const PINK    = fg(211);  // soft pink
const GRAY    = fg(242);  // subtle gray
const WHITE   = fg(255);
const GREEN   = fg(114);  // soft green
const YELLOW  = fg(220);  // warm yellow
const RED     = fg(203);  // soft red

function colorFor(pct) {
  if (pct == null) return GRAY;
  if (pct >= 90) return RED;
  if (pct >= 70) return ORANGE;
  if (pct >= 50) return YELLOW;
  return GREEN;
}

// Smooth gradient bar using partial block characters
function smoothBar(pct, width = 10) {
  if (pct == null) return `${GRAY}${'░'.repeat(width)}${RST}`;
  const p = Math.min(100, Math.max(0, Math.round(pct)));
  const total = p * width / 100;
  const full = Math.floor(total);
  const remainder = total - full;
  const empty = width - full - (remainder > 0 ? 1 : 0);

  // Partial block characters: ▏▎▍▌▋▊▉█
  const partials = [' ', '▏', '▎', '▍', '▌', '▋', '▊', '▉'];
  const partialChar = remainder > 0 ? partials[Math.round(remainder * 7)] : '';

  const c = colorFor(p);
  return `${c}${'▓'.repeat(full)}${partialChar}${GRAY}${'░'.repeat(empty)}${RST}`;
}

function timeUntil(isoStr) {
  if (!isoStr) return '';
  const diff = Math.max(0, new Date(isoStr) - Date.now());
  const h = Math.floor(diff / 3600000);
  const m = Math.floor((diff % 3600000) / 60000);
  return `${h}h${String(m).padStart(2, '0')}m`;
}

// Fetch + cache usage
function refreshUsageCache() {
  try {
    const creds = JSON.parse(fs.readFileSync(CREDS_PATH, 'utf8'));
    const token = creds.claudeAiOauth?.accessToken;
    if (!token) return;
    fetch('https://api.anthropic.com/api/oauth/usage', {
      headers: {
        'Authorization': `Bearer ${token}`,
        'anthropic-beta': 'oauth-2025-04-20',
      },
    })
      .then(r => r.json())
      .then(data => {
        data._ts = Date.now();
        fs.writeFileSync(CACHE_PATH, JSON.stringify(data));
      })
      .catch(() => {});
  } catch {}
}

function readUsageCache() {
  try {
    const data = JSON.parse(fs.readFileSync(CACHE_PATH, 'utf8'));
    if (Date.now() - (data._ts || 0) > CACHE_TTL) refreshUsageCache();
    return data;
  } catch {
    refreshUsageCache();
    return null;
  }
}

// Main
let input = '';
process.stdin.on('data', chunk => (input += chunk));
process.stdin.on('end', () => {
  let session = {};
  try { session = JSON.parse(input); } catch {}

  const model = (session.model?.display_name || '?').split(' ').pop();
  const ctxPct = Math.round(session.context_window?.used_percentage || 0);
  const cost = (session.cost?.total_cost_usd || 0).toFixed(2);
  const usage = readUsageCache();

  let parts = [];

  // Working directory
  const cwd = session.cwd || session.workspace?.current_dir || '';
  if (cwd) {
    const home = process.env.HOME || process.env.USERPROFILE || '';
    const displayCwd = home ? cwd.replace(home, '~') : cwd;
    parts.push(`${BOLD}${TEAL}${displayCwd}${RST}`);
  }

  // Model badge
  parts.push(`${BOLD}${PURPLE}◆ ${model}${RST}`);

  // Separator
  const SEP = `${GRAY}│${RST}`;

  // 5-hour session limit
  if (usage?.five_hour?.utilization != null) {
    const u = Math.round(usage.five_hour.utilization);
    const reset = timeUntil(usage.five_hour.resets_at);
    parts.push(`${SEP}  ${BLUE}⏱ 5h${RST} ${smoothBar(u)} ${colorFor(u)}${BOLD}${u}%${RST}${reset ? `  ${GRAY}↻ ${reset}${RST}` : ''}`);
  }

  // 7-day weekly limit
  if (usage?.seven_day?.utilization != null) {
    const u = Math.round(usage.seven_day.utilization);
    parts.push(`${SEP}  ${TEAL}◇ 7d${RST} ${smoothBar(u)} ${colorFor(u)}${BOLD}${u}%${RST}`);
  }

  // Context window
  if (ctxPct > 0) {
    parts.push(`${SEP}  ${PINK}⬡ ctx${RST} ${colorFor(ctxPct)}${ctxPct}%${RST}`);
  }

  // Cost
  parts.push(`${SEP}  ${ORANGE}$ ${cost}${RST}`);

  process.stdout.write(` ${parts.join(' ')} `);
});
