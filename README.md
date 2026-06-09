# Claude Code Config

Personal Claude Code configuration backup. Clone and run `setup.sh` to restore on a new machine.

> **[OPTIMIZATION.md](OPTIMIZATION.md)** — the playbook behind this config: what's
> done, what's recommended next, and the menu of capability upgrades (with trade-offs).

## Quick Start

```bash
git clone https://github.com/smallgiraffe0110/claude-config.git
cd claude-config
bash setup.sh
```

Then restart your terminal (or re-source your shell rc — `~/.zshrc` on macOS).

## What's Included

| File | Purpose |
|---|---|
| `settings.json` | Global settings — permissions mode, model (`claude-opus-4-8`), effort (`xhigh`), plugins, marketplaces, status line |
| `settings.local.json` | Local/project-scoped Bash permissions and disabled MCP servers |
| `CLAUDE.md` | Global instructions (effort, projects home, tech stack, coding style, verification, gstack skills) |
| `statusline.js` | Custom status line script |
| `session-namer.js` | Helper that derives a short session name from the first prompt (standalone util) |
| `shell-helpers.zsh` | Dev-workflow helpers — `newproj`, `newnext`, `repos`, `$PROJECTS`, PATH/env. `setup.sh` sources it from `~/.zshrc` |
| `hooks/verify.js` | Verification hook — eslint per edit + project typecheck at turn-end (see below) |
| `memory/` | Persistent memory files (user identity, feedback) |

## External Prerequisites

`setup.sh` restores config but **cannot install these** — it checks for them and
warns if missing:

| Tool | Needed for | Install |
|---|---|---|
| **Node.js** | Claude Code, statusline, `newnext` | Node LTS |
| **git** | version control, `newproj` | system pkg manager |
| **gita** | `repos` dashboard, `newproj`/`newnext` repo registration | `pipx install gita` or `brew install gita` |
| **gstack** | `/browse` + the ~40 skills in CLAUDE.md's gstack section | gstack install docs |
| fzf, lazygit, bun | optional shell-helper niceties | optional |

### Plugins enabled

`superpowers` + `superpowers-lab` (obra/superpowers-marketplace), `caveman`
(JuliusBrussee/caveman), `startup-skills` (quinnhall07/startup-skills), and the
official `frontend-design` + `vercel` plugins. They auto-install on first launch.

> Note: the `vercel-vercel-plugin` marketplace entry in `settings.json` points at
> a machine-local `.cache/plugins/.install-staging/...` path and is **disabled**.
> It won't resolve on another machine — drop it (or repoint it) on restore.

## Verification Hooks

`hooks/verify.js` (wired in `settings.json`) closes the gap between "Claude says
done" and "actually compiles". It's **global but free outside JS/TS projects** —
it bails instantly when there's no `package.json`/`tsconfig.json`.

| Event | Action |
|---|---|
| `PostToolUse` (Edit/Write/MultiEdit) | `eslint --fix` the changed `.ts/.tsx/.js/...` file; surface any remaining problems |
| `Stop` (turn end) | `npm run typecheck` (if defined) else `npx tsc --noEmit`; **blocks the turn** on type errors so Claude fixes them first |

Only uses project-local binaries (`node_modules/.bin`), so it never installs
anything. The `Stop` hook honors `stop_hook_active` to avoid loops. To soften it
to advisory, change the `Stop` hook command's behavior (or remove the `Stop` block).

## Context7 MCP

Real-time, version-specific library docs injected at request time — kills
hallucinated/outdated APIs (big win for fast-moving Next.js/Vercel). `setup.sh`
adds it at user scope (idempotent):

```bash
claude mcp add --transport http --scope user context7 https://mcp.context7.com/mcp
```

API key optional (`context7.com/dashboard` for higher rate limits). It lives in
`~/.claude.json`, not `settings.json`, which is why setup adds it via the CLI.
Usage: say "use context7" in a prompt when working against a library API.

## Persistent Max Effort

Current Claude Code persists effort directly via `"effortLevel"` in `settings.json`
(this backup ships `xhigh`, the top tier — formerly surfaced as `max`). That alone
makes it stick across terminal sessions.

`setup.sh` *also* exports `CLAUDE_CODE_EFFORT_LEVEL=max` as a fallback — it covers
desktop-app launches and older builds. It writes to:

1. **Your shell rc** (`~/.zshrc` on macOS, `~/.bashrc` on Linux) — terminal sessions
2. **Windows user environment variable** (if on Windows) — desktop-app launches

### Manual setup (if not using setup.sh)

**Preferred — settings.json:**
```json
{ "effortLevel": "xhigh" }
```

**Fallback env var (macOS/Linux):**
```bash
echo 'export CLAUDE_CODE_EFFORT_LEVEL=max' >> ~/.zshrc   # ~/.bashrc on Linux
source ~/.zshrc
```

**Windows (PowerShell):**
```powershell
[System.Environment]::SetEnvironmentVariable('CLAUDE_CODE_EFFORT_LEVEL', 'max', 'User')
```
Then restart Claude Code.

## Deliberately Excluded

Not backed up **on purpose** (regenerated or machine-local — not lost):

- **Runtime/ephemeral:** `sessions/`, `tasks/`, `history.jsonl`, `*-cache.json`, `telemetry/`, `daemon.log`, `vercel-plugin-device-id`.
- **Plugin caches** (`plugins/cache/…`) — reinstalled from the marketplaces declared in `settings.json` on first launch.
- **`skills/`** — gstack / Cloudflare / Vercel skills are managed by their own installers (gstack skills are a separate git repo).
- No custom user-level `agents/`, `commands/`, or `hooks/` exist, so there's nothing to back up there.

> Heads-up: the `vercel-vercel-plugin` marketplace in `settings.json` is a
> **disabled** entry pointing at a machine-local `.cache/.../install-staging`
> path — it won't resolve elsewhere. The active Vercel plugin is
> `vercel@claude-plugins-official`. Remove the stale entry on restore if it nags.
