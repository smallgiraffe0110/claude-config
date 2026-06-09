---
name: claude-config-repo
description: "Location and sync workflow for the user's Claude Code config backup repo"
metadata: 
  node_type: memory
  type: project
  originSessionId: aa0b98b0-9381-43da-bf4f-dba974a2ff74
---

User's Claude Code config is backed up to the **public** GitHub repo `smallgiraffe0110/claude-config` (default branch `master`). No standing local clone — clone into `~/code/claude-config` when needed.

It mirrors `~/.claude`: `CLAUDE.md`, `settings.json`, `settings.local.json`, `statusline.js`, `session-namer.js`, `shell-helpers.zsh`, `memory/` (mirrors `~/.claude/projects/-Users-hunterearls/memory/`). `setup.sh` restores it on a new machine (copies files, sources shell-helpers from `~/.zshrc`, checks prereqs: node/git/gita + gstack skills dir).

**Why:** "update the config repo" means sync live `~/.claude` → this repo, commit, push.
**How to apply:** Diff live vs repo, copy live→repo, `git rm` dead memory, commit as Hunter Earls ([[user-identity]]), push to `master`. Repo is public — scan for secrets before pushing. Deliberately excluded: runtime/caches/`skills/`/plugin caches.
