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

echo "Done! Claude Code config restored."
echo "Plugins will auto-install on first launch."
