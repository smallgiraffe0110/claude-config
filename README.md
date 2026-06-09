# Claude Code Config

Personal Claude Code configuration backup. Clone and run `setup.sh` to restore on a new machine.

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
| `settings.json` | Global settings — permissions mode, effort level, plugins, marketplaces, status line |
| `settings.local.json` | Local/project-scoped Bash permissions and disabled MCP servers |
| `CLAUDE.md` | Global instructions (effort, projects home, tech stack, coding style, gstack skills) |
| `statusline.js` | Custom status line script |
| `memory/` | Persistent memory files (user identity, feedback) |

### Plugins enabled

`superpowers` + `superpowers-lab` (obra/superpowers-marketplace), `caveman`
(JuliusBrussee/caveman), `startup-skills` (quinnhall07/startup-skills), and the
official `frontend-design` + `vercel` plugins. They auto-install on first launch.

> Note: the `vercel-vercel-plugin` marketplace entry in `settings.json` points at
> a machine-local `.cache/plugins/.install-staging/...` path and is **disabled**.
> It won't resolve on another machine — drop it (or repoint it) on restore.

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
