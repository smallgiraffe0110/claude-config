#!/bin/bash
# Restore Claude Code config on a new machine
# Usage: git clone <this-repo> && cd claude-config && bash setup.sh

set -e

CLAUDE_DIR="$HOME/.claude"
# Memory lives under a project dir derived from the launch cwd. On this macOS
# setup (~ = /Users/hunterearls) that slugifies to "-Users-hunterearls".
# Override by exporting PROJECT_MEMORY before running on a different machine.
PROJECT_MEMORY="${PROJECT_MEMORY:-$CLAUDE_DIR/projects/-Users-hunterearls/memory}"

mkdir -p "$CLAUDE_DIR"
mkdir -p "$PROJECT_MEMORY"

cp settings.json "$CLAUDE_DIR/settings.json"
cp settings.local.json "$CLAUDE_DIR/settings.local.json"
cp CLAUDE.md "$CLAUDE_DIR/CLAUDE.md"
cp statusline.js "$CLAUDE_DIR/statusline.js"
cp memory/*.md "$PROJECT_MEMORY/"

# --- Max effort level (persistent) ---
# Newer Claude Code persists effort via "effortLevel" in settings.json (this
# backup ships "xhigh", the top tier) so the env var below is now a belt-and-
# suspenders fallback — it also covers desktop-app launches that don't read
# settings the same way. Harmless to keep.

EFFORT_LINE='export CLAUDE_CODE_EFFORT_LEVEL=max'

# Append to whichever login shells exist (zsh is macOS default; bash on Linux).
for RC in "$HOME/.zshrc" "$HOME/.bashrc"; do
  [ -e "$RC" ] || { [ "$RC" = "$HOME/.zshrc" ] && [ "${SHELL##*/}" = "zsh" ] && touch "$RC"; }
  [ -e "$RC" ] || continue
  if ! grep -qF "$EFFORT_LINE" "$RC" 2>/dev/null; then
    echo "" >> "$RC"
    echo "# Claude Code - always use max effort" >> "$RC"
    echo "$EFFORT_LINE" >> "$RC"
    echo "Added CLAUDE_CODE_EFFORT_LEVEL=max to $RC"
  fi
done

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
echo "Restart your terminal (or re-source your shell rc) to apply effort level."
