# Claude Code Config

Personal Claude Code configuration backup. Clone and run `setup.sh` to restore on a new machine.

## Quick Start

```bash
git clone https://github.com/smallgiraffe0110/claude-config.git
cd claude-config
bash setup.sh
```

Then restart your terminal (or run `source ~/.bashrc`).

## What's Included

| File | Purpose |
|---|---|
| `settings.json` | Global settings — model, permissions, plugins, status line |
| `settings.local.json` | Local/project-scoped permissions and disabled MCP servers |
| `CLAUDE.md` | Global instructions (tech stack, coding style, conventions) |
| `statusline.js` | Custom status line script |
| `memory/` | Persistent memory files (feedback, project context) |

## Persistent Max Effort

Claude Code's `max` effort level (Opus 4.6 only) does **not** persist via `settings.json` — only `low`, `medium`, and `high` do.

To make `max` stick across sessions, `setup.sh` sets the `CLAUDE_CODE_EFFORT_LEVEL` environment variable in two places:

1. **`~/.bashrc`** — picked up by terminal-launched sessions
2. **Windows user environment variable** (if on Windows) — picked up when Claude Code is launched from the desktop app

### Manual setup (if not using setup.sh)

**Linux/macOS:**
```bash
echo 'export CLAUDE_CODE_EFFORT_LEVEL=max' >> ~/.bashrc
source ~/.bashrc
```

**Windows (PowerShell):**
```powershell
[System.Environment]::SetEnvironmentVariable('CLAUDE_CODE_EFFORT_LEVEL', 'max', 'User')
```
Then restart Claude Code.

### Why not settings.json?

The `/effort` command supports four levels: `low`, `medium`, `high`, and `max`. The first three persist in settings automatically. `max` is intentionally session-only by default (it's slower and more expensive), so the only way to persist it is through the `CLAUDE_CODE_EFFORT_LEVEL` environment variable.
