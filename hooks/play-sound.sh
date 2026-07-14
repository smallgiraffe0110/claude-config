#!/bin/sh
# Play a macOS system sound with minimal latency via claude-sound-daemon.
# Usage: play-sound.sh <SoundName|/abs/path.aiff>   or   play-sound.sh start [SoundName]
# "start" ensures the daemon is up, then plays the spawn sound (default: Hero).
# Falls back to afplay (and starts the daemon) if the daemon isn't running.
DAEMON="$HOME/.claude/hooks/claude-sound-daemon"
FIFO="$HOME/.claude/hooks/sound-fifo"

# Match by name, not full path: the daemon may have been launched via a
# relative path, and a missed match here spawns duplicate daemons.
daemon_running() { /usr/bin/pgrep -qf claude-sound-daemon; }

start_daemon() {
  [ -x "$DAEMON" ] || return 1
  daemon_running || /usr/bin/nohup "$DAEMON" >/dev/null 2>&1 &
}

case "$1" in
  "") start_daemon; exit 0 ;;
  start) SOUND="${2:-Hero}" ;;
  *) SOUND="$1" ;;
esac

# Only use the FIFO when the daemon was already running before this call;
# a freshly spawned daemon may not have recreated the FIFO yet, and writing
# to the previous daemon's stale FIFO blocks forever (no reader).
if daemon_running && [ -p "$FIFO" ]; then
  printf '%s\n' "$SOUND" > "$FIFO"
else
  start_daemon
  case "$SOUND" in
    /*) FILE="$SOUND" ;;
    *) FILE="/System/Library/Sounds/$SOUND.aiff" ;;
  esac
  /usr/bin/afplay "$FILE" >/dev/null 2>&1 &
fi
