#!/bin/bash
# Restore Claude Code config on a new machine
# Usage: git clone <this-repo> && cd claude-config && bash setup.sh

set -e

CLAUDE_DIR="$HOME/.claude"
PROJECT_MEMORY="$CLAUDE_DIR/projects/C--Users-hunte/memory"

mkdir -p "$CLAUDE_DIR"
mkdir -p "$PROJECT_MEMORY"

cp settings.json "$CLAUDE_DIR/settings.json"
cp settings.local.json "$CLAUDE_DIR/settings.local.json"
cp CLAUDE.md "$CLAUDE_DIR/CLAUDE.md"
cp statusline.js "$CLAUDE_DIR/statusline.js"
cp memory/*.md "$PROJECT_MEMORY/"

# --- Max effort level (persistent) ---
# The "max" effort level only persists via the CLAUDE_CODE_EFFORT_LEVEL env var.
# Lower levels (low/medium/high) can use settings.json, but max cannot.

BASHRC="$HOME/.bashrc"
EFFORT_LINE='export CLAUDE_CODE_EFFORT_LEVEL=max'

if ! grep -qF "$EFFORT_LINE" "$BASHRC" 2>/dev/null; then
  echo "" >> "$BASHRC"
  echo "# Claude Code - always use max effort" >> "$BASHRC"
  echo "$EFFORT_LINE" >> "$BASHRC"
  echo "Added CLAUDE_CODE_EFFORT_LEVEL=max to $BASHRC"
fi

# On Windows, also set the user environment variable so it works
# when Claude Code is launched from the desktop app (not a terminal).
if command -v powershell.exe &>/dev/null; then
  powershell.exe -Command \
    "[System.Environment]::SetEnvironmentVariable('CLAUDE_CODE_EFFORT_LEVEL', 'max', 'User')"
  echo "Set Windows user environment variable CLAUDE_CODE_EFFORT_LEVEL=max"
fi

echo ""
echo "Done! Claude Code config restored."
echo "Plugins will auto-install on first launch."
echo "Restart your terminal (or run 'source ~/.bashrc') to apply effort level."
