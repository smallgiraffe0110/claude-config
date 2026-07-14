#!/bin/sh
# Idle alarm for Claude Code: if the session sits waiting on a reply for
# 30+ minutes, sound an alarm repeatedly until the user responds or the
# window closes. Stays quiet while the session is still working (shell
# commands, dev servers, background agents/workflows).
#
# Hook usage (JSON on stdin):  idle-alarm.sh arm     (SessionStart)
#                              idle-alarm.sh disarm  (SessionEnd)
# Internal:                    idle-alarm.sh watch <claude_pid> <transcript> <session_id>
#
# Tunables (env): CLAUDE_IDLE_ALARM_SECS (default 1800),
#   CLAUDE_IDLE_ALARM_INTERVAL (default 15), CLAUDE_IDLE_ALARM_SOUND (Sosumi)

IDLE_SECS="${CLAUDE_IDLE_ALARM_SECS:-1800}"
ALARM_INTERVAL="${CLAUDE_IDLE_ALARM_INTERVAL:-15}"
SOUND="${CLAUDE_IDLE_ALARM_SOUND:-Sosumi}"
RUN_DIR="$HOME/.claude/hooks/idle-alarm"
mkdir -p "$RUN_DIR"

# Walk up from this process to find the claude CLI process.
claude_ancestor() {
  _p=$PPID
  while [ -n "$_p" ] && [ "$_p" -gt 1 ] 2>/dev/null; do
    case "$(ps -o comm= -p "$_p" 2>/dev/null | tr -d ' ')" in
      claude|*/claude) printf '%s\n' "$_p"; return 0 ;;
    esac
    _p=$(ps -o ppid= -p "$_p" 2>/dev/null | tr -d ' ')
  done
  return 1
}

# Full descendant list from the raw process table (pgrep -P silently
# omits its own ancestors on macOS, hiding the very shells we look for).
list_descendants() {
  ps -axo pid=,ppid= | awk -v root="$1" '
    { pid[NR] = $1; pp[NR] = $2 }
    END {
      want[root] = 1; changed = 1
      while (changed) {
        changed = 0
        for (i = 1; i <= NR; i++)
          if (want[pp[i]] && !want[pid[i]]) { want[pid[i]] = 1; changed = 1 }
      }
      for (i = 1; i <= NR; i++)
        if (want[pid[i]] && pid[i] != root) print pid[i]
    }'
}

# Busy = the session is running actual work: a shell in claude's process
# tree (every Bash tool command runs via one, foreground or background)
# or a descendant listening on a TCP port (dev server). Session
# infrastructure (MCP servers, LSP servers, caffeinate) is stdio-based
# and matches neither.
busy() {
  _pids=$(list_descendants "$1")
  [ -n "$_pids" ] || return 1
  for _pid in $_pids; do
    case "$(ps -o comm= -p "$_pid" 2>/dev/null | tr -d ' ')" in
      zsh|bash|sh|*/zsh|*/bash|*/sh) return 0 ;;
    esac
  done
  _plist=$(printf '%s' "$_pids" | tr '\n' ',' | sed 's/,$//')
  lsof -a -p "$_plist" -iTCP -sTCP:LISTEN >/dev/null 2>&1 && return 0
  return 1
}

# Latest activity: main transcript mtime, plus anything in the session's
# side directory (subagent output, workflows, tool results).
newest_activity() {
  _t=$(stat -f %m "$2" 2>/dev/null || echo 0)
  _sdir="${2%.jsonl}"
  if [ -d "$_sdir" ]; then
    _t2=$(find "$_sdir" -type f -exec stat -f %m {} + 2>/dev/null | sort -n | tail -1)
    [ -n "$_t2" ] && [ "$_t2" -gt "$_t" ] && _t=$_t2
  fi
  printf '%s\n' "$_t"
}

case "$1" in
  check)
    # Debug: idle-alarm.sh check <claude_pid> <transcript>
    _last=$(newest_activity _ "$3")
    echo "idle: $(( $(date +%s) - _last ))s (threshold ${IDLE_SECS}s)"
    if busy "$2"; then echo "busy: yes (alarm suppressed)"; else echo "busy: no"; fi
    ;;

  arm)
    IN=$(cat)
    SID=$(printf '%s' "$IN" | jq -r '.session_id // empty')
    TRANSCRIPT=$(printf '%s' "$IN" | jq -r '.transcript_path // empty')
    [ -n "$SID" ] && [ -n "$TRANSCRIPT" ] || exit 0
    CLAUDE_PID=$(claude_ancestor) || exit 0
    PIDFILE="$RUN_DIR/$SID.pid"
    [ -f "$PIDFILE" ] && kill "$(cat "$PIDFILE")" 2>/dev/null
    nohup "$0" watch "$CLAUDE_PID" "$TRANSCRIPT" "$SID" >/dev/null 2>&1 &
    printf '%s\n' "$!" > "$PIDFILE"
    ;;

  disarm)
    IN=$(cat)
    SID=$(printf '%s' "$IN" | jq -r '.session_id // empty')
    [ -n "$SID" ] || exit 0
    PIDFILE="$RUN_DIR/$SID.pid"
    [ -f "$PIDFILE" ] && kill "$(cat "$PIDFILE")" 2>/dev/null
    rm -f "$PIDFILE"
    ;;

  watch)
    CLAUDE_PID=$2 TRANSCRIPT=$3 SID=$4
    while kill -0 "$CLAUDE_PID" 2>/dev/null; do
      _last=$(newest_activity _ "$TRANSCRIPT")
      _idle=$(( $(date +%s) - _last ))
      if [ "$_idle" -lt "$IDLE_SECS" ]; then
        _w=$((IDLE_SECS - _idle))
        [ "$_w" -gt 60 ] && _w=60
        [ "$_w" -lt 2 ] && _w=2
        sleep "$_w"
        continue
      fi
      if busy "$CLAUDE_PID"; then
        sleep 60
        continue
      fi
      echo "$(date '+%F %T') alarm sid=$SID idle=${_idle}s" >> "$RUN_DIR/alarm.log"
      "$HOME/.claude/hooks/play-sound.sh" "$SOUND"
      sleep "$ALARM_INTERVAL"
    done
    rm -f "$RUN_DIR/$SID.pid"
    ;;
esac
