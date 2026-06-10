#!/bin/bash
# Restore Claude Code config on a new machine.
# Usage: git clone <this-repo> && cd claude-config && bash setup.sh
#
# Idempotent: safe to re-run. Copies config into ~/.claude, wires shell helpers
# into ~/.zshrc, and prints the external prerequisites it can't install for you.

set -e

CLAUDE_DIR="$HOME/.claude"
# Memory lives under a project dir derived from the launch cwd. On this macOS
# setup (~ = /Users/hunterearls) that slugifies to "-Users-hunterearls".
# Override by exporting PROJECT_MEMORY before running on a different machine.
PROJECT_MEMORY="${PROJECT_MEMORY:-$CLAUDE_DIR/projects/-Users-hunterearls/memory}"

mkdir -p "$CLAUDE_DIR"
mkdir -p "$PROJECT_MEMORY"

# --- Core config files ---
cp settings.json        "$CLAUDE_DIR/settings.json"
cp settings.local.json  "$CLAUDE_DIR/settings.local.json"
cp CLAUDE.md            "$CLAUDE_DIR/CLAUDE.md"
cp statusline.js        "$CLAUDE_DIR/statusline.js"
cp session-namer.js     "$CLAUDE_DIR/session-namer.js"
cp shell-helpers.zsh    "$CLAUDE_DIR/shell-helpers.zsh"
cp memory/*.md          "$PROJECT_MEMORY/"
mkdir -p "$CLAUDE_DIR/hooks"
cp hooks/*.js           "$CLAUDE_DIR/hooks/"   # verification hooks (typecheck + lint)
echo "Copied config into $CLAUDE_DIR"

# --- Context7 MCP (real-time, version-specific library docs) ---
# Lives in ~/.claude.json (user scope), not settings.json, so add it via the CLI.
if command -v claude >/dev/null 2>&1; then
  if claude mcp list 2>/dev/null | grep -qi context7; then
    echo "Context7 MCP already configured"
  else
    if claude mcp add --transport http --scope user context7 https://mcp.context7.com/mcp >/dev/null 2>&1; then
      echo "Added Context7 MCP (user scope)"
    else
      echo "Could not add Context7 MCP — add manually:"
      echo "  claude mcp add --transport http --scope user context7 https://mcp.context7.com/mcp"
    fi
  fi
else
  echo "Skipped Context7 MCP — 'claude' CLI not on PATH"
fi

# --- Dev-workflow shell helpers (newproj/newnext/repos, $PROJECTS, PATH) ---
# CLAUDE.md references these; source them from ~/.zshrc so they exist on login.
ZSHRC="$HOME/.zshrc"
[ -e "$ZSHRC" ] || touch "$ZSHRC"
if ! grep -qF "shell-helpers.zsh" "$ZSHRC" 2>/dev/null; then
  {
    echo ""
    echo "# Claude config — dev-workflow helpers"
    echo '[ -f "$HOME/.claude/shell-helpers.zsh" ] && source "$HOME/.claude/shell-helpers.zsh"'
  } >> "$ZSHRC"
  echo "Sourced shell-helpers.zsh from $ZSHRC"
fi

# --- Max effort level (persistent) ---
# Newer Claude Code persists effort via "effortLevel" in settings.json (this
# backup ships "xhigh", the top tier) so the env var below is now a belt-and-
# suspenders fallback — it also covers desktop-app launches that don't read
# settings the same way. Harmless to keep.
EFFORT_LINE='export CLAUDE_CODE_EFFORT_LEVEL=max'
for RC in "$HOME/.zshrc" "$HOME/.bashrc"; do
  [ -e "$RC" ] || { [ "$RC" = "$HOME/.zshrc" ] && [ "${SHELL##*/}" = "zsh" ] && touch "$RC"; }
  [ -e "$RC" ] || continue
  if ! grep -qF "$EFFORT_LINE" "$RC" 2>/dev/null; then
    printf '\n# Claude Code - always use max effort\n%s\n' "$EFFORT_LINE" >> "$RC"
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

# --- Prerequisite check (these are NOT bundled — install separately) ---
echo ""
echo "Checking external prerequisites referenced by this config:"
check() { if command -v "$1" >/dev/null 2>&1; then echo "  [ok]      $1 — $2"; else echo "  [MISSING] $1 — $2 ($3)"; fi; }
check node "Claude Code, statusline, newnext" "install Node.js LTS"
check git  "version control / newproj"        "install git"
check gita "'repos' dashboard + newproj/newnext registration" "pipx install gita  (or: brew install gita)"
# gstack ships as Claude Code skills (not a PATH binary) — check the skills dir.
if [ -d "$CLAUDE_DIR/skills/gstack" ]; then
  echo "  [ok]      gstack — /browse + ~40 skills in CLAUDE.md's gstack section"
else
  echo "  [MISSING] gstack — /browse + skills referenced in CLAUDE.md (install gstack; it populates ~/.claude/skills/gstack)"
fi
echo "  (optional) fzf, lazygit, bun — used by shell helpers if present"

echo ""
echo "Done! Claude Code config restored."
echo "Plugins (frontend-design, vercel, startup-skills, superpowers) auto-install on first launch."
echo "Restart your terminal (or 'source ~/.zshrc') to load helpers + effort level."
