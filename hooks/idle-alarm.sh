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

list_descendants() {
  for _k in $(pgrep -P "$1" 2>/dev/null); do
    printf '%s\n' "$_k"
    list_descendants "$_k"
  done
}

etime_secs() {
  ps -o etime= -p "$1" 2>/dev/null | awk '
    NF { n = split($1, a, /[-:]/); s = 0
         if (n == 4) s = a[1]*86400 + a[2]*3600 + a[3]*60 + a[4]
         else if (n == 3) s = a[1]*3600 + a[2]*60 + a[3]
         else if (n == 2) s = a[1]*60 + a[2]
         print s }'
}

# Busy = the session spawned work after startup that is still running
# (foreground/background shell commands, dev servers). MCP servers and
# other session-startup children are ignored via a 2-minute age grace.
busy() {
  _claude_age=$(etime_secs "$1")
  [ -n "$_claude_age" ] || return 1
  for _pid in $(list_descendants "$1"); do
    _age=$(etime_secs "$_pid")
    [ -n "$_age" ] || continue
    if [ $((_claude_age - _age)) -gt 120 ]; then return 0; fi
  done
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
