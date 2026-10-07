#!/bin/bash
# Keep ~/code focused: everything at its top level that is not a main project
# moves into ~/code/_archive. Moves only — never deletes.
#
#   bash tidy-code.sh           dry run, prints what would move
#   bash tidy-code.sh --apply   actually move
#
# Edit KEEP when the list of main projects changes.

set -u

CODE="${PROJECTS:-$HOME/code}"
ARCHIVE="$CODE/_archive"
KEEP=(
  implemented-systems
  medspa-systems
  systems-review-preview
  systems-copy-review-2026-09-29
  claude-config
  _side
  _archive
)

APPLY=0
[ "${1:-}" = "--apply" ] && APPLY=1

cd "$CODE" 2>/dev/null || { echo "no $CODE — nothing to tidy"; exit 0; }
[ "$APPLY" = 1 ] && mkdir -p "$ARCHIVE" "$CODE/_side"

is_kept() {
  local k
  for k in "${KEEP[@]}"; do [ "$k" = "$1" ] && return 0; done
  return 1
}

# Dev servers left running from a folder break when it moves; warn, don't kill.
running=$(lsof -a -d cwd -c node -c python -c Python 2>/dev/null | awk -v c="$CODE/" 'index($NF, c) == 1 {print $NF}' | sort -u)

moved=0
for d in *; do
  [ -e "$d" ] || continue
  is_kept "$d" && continue
  if [ -e "$ARCHIVE/$d" ]; then echo "skip (already in archive): $d"; continue; fi
  if echo "$running" | grep -q "^$CODE/$d\(/\|$\)"; then echo "skip (process running inside): $d"; continue; fi
  if [ "$APPLY" = 1 ]; then
    mv "$d" "$ARCHIVE/$d" && echo "archived: $d" && moved=$((moved + 1))
  else
    echo "would archive: $d"
    moved=$((moved + 1))
  fi
done

if [ "$APPLY" = 1 ]; then
  # Linked git worktrees store absolute paths; fix any that moved.
  for g in "$ARCHIVE"/*/.git; do
    [ -d "$g/worktrees" ] || continue
    repo=$(dirname "$g")
    for wt in "$ARCHIVE"/*/*/.git; do
      [ -f "$wt" ] && git -C "$repo" worktree repair "$(dirname "$wt")" >/dev/null 2>&1
    done
  done
  echo "done: $moved archived into $ARCHIVE"
else
  echo "dry run: $moved would move. Re-run with --apply."
fi
