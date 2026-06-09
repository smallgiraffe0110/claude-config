# Claude config — dev-workflow shell helpers
# Installed to ~/.claude/shell-helpers.zsh and sourced from ~/.zshrc by setup.sh.
# Everything here is guarded so it no-ops cleanly if a tool/dir is absent.

# --- PATH / env (only prepend if the dir actually exists) ---
[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"   # gita, hermes, etc.
export BUN_INSTALL="$HOME/.bun"
[ -d "$BUN_INSTALL/bin" ] && export PATH="$BUN_INSTALL/bin:$PATH"
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
[ -f "$HOME/.cargo/env" ]     && . "$HOME/.cargo/env"
[ -s "$HOME/.bun/_bun" ]      && source "$HOME/.bun/_bun"           # bun completions

# --- Projects home (CLAUDE.md assumes ~/code is the workspace root) ---
export PROJECTS="$HOME/code"

# --- fzf integration (Ctrl-r history, Ctrl-t files, completions) ---
command -v fzf >/dev/null 2>&1 && source <(fzf --zsh)

# --- Repo fleet dashboard + bulk ops (requires: gita) ---
alias repos='gita ll'                    # status of every repo at a glance
alias repos-fetch='gita super -q fetch'  # fetch all repos
alias lg='lazygit'

# Start a new project in ~/code, git-init it, register with gita, cd in.
newproj() {
  if [[ -z "$1" ]]; then echo "usage: newproj <name>"; return 1; fi
  local dir="$PROJECTS/$1"
  if [[ -e "$dir" ]]; then echo "exists: $dir"; return 1; fi
  mkdir -p "$dir" && cd "$dir" && git init -q
  command -v gita >/dev/null 2>&1 && gita add "$dir" >/dev/null 2>&1
  echo "created $dir"
}

# Scaffold a Next.js + TS + Tailwind app in ~/code (matches CLAUDE.md tech stack).
newnext() {
  if [[ -z "$1" ]]; then echo "usage: newnext <name>"; return 1; fi
  cd "$PROJECTS" || return 1
  npx create-next-app@latest "$1" --ts --tailwind --eslint --app --src-dir --use-npm \
    && cd "$PROJECTS/$1" \
    && { command -v gita >/dev/null 2>&1 && gita add "$PROJECTS/$1" >/dev/null 2>&1; }
}
