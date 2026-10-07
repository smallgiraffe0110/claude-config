---
name: claude-config-repo
description: "Location and sync workflow for the user's Claude Code config backup repo"
metadata: 
  node_type: memory
  type: project
  originSessionId: aa0b98b0-9381-43da-bf4f-dba974a2ff74
---

User's Claude Code config is backed up to the **public** GitHub repo `smallgiraffe0110/claude-config` (default branch `master`). Standing local clone at `~/code/claude-config` on the laptop and `~/claude-config` on the other machine (git identity already set to Hunter Earls — matches [[user-identity]]); pull before editing, push to `master`.

It mirrors `~/.claude`: `CLAUDE.md`, `settings.json`, `settings.local.json`, `statusline.js`, `session-namer.js`, `shell-helpers.zsh`, `hooks/verify.js`, `memory/` (mirrors `~/.claude/projects/-Users-hunterearls/memory/`). `tidy-code.sh` (dry-run by default, `--apply` to move) archives everything in `~/code` except the main projects into `~/code/_archive`. Only non-project memory is mirrored (repo is public): index, feedback, identity, current focus, file layout, this note — project notes stay local. `setup.sh` restores it on a new machine (copies files, installs hooks, sources shell-helpers from `~/.zshrc`, adds Context7 MCP, checks prereqs: node/git/gita + gstack skills dir).

Active capability upgrades (see `OPTIMIZATION.md` in the repo): global **verification hooks** (`~/.claude/hooks/verify.js` — eslint per edit + `tsc --noEmit` at turn-end, blocks on type errors, no-ops outside JS/TS projects) and **Context7 MCP** (user scope, real-time library docs; say "use context7"). 

**Why:** "update the config repo" means sync live `~/.claude` → this repo, commit, push.
**How to apply:** Diff live vs repo, copy live→repo, `git rm` dead memory, commit as Hunter Earls ([[user-identity]]), push to `master`. Repo is public — scan for secrets before pushing. Deliberately excluded: runtime/caches/`skills/`/plugin caches.
