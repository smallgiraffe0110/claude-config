#!/bin/sh
# Play a macOS system sound with minimal latency via claude-sound-daemon.
# Usage: play-sound.sh <SoundName|/abs/path.aiff>   or   play-sound.sh start
# Falls back to afplay (and starts the daemon) if the daemon isn't running.
DAEMON="$HOME/.claude/hooks/claude-sound-daemon"
FIFO="$HOME/.claude/hooks/sound-fifo"

daemon_running() { /usr/bin/pgrep -qf "$DAEMON"; }

start_daemon() {
  [ -x "$DAEMON" ] || return 1
  daemon_running || /usr/bin/nohup "$DAEMON" >/dev/null 2>&1 &
}

case "$1" in
  start|"") start_daemon; exit 0 ;;
esac

if daemon_running && [ -p "$FIFO" ]; then
  printf '%s\n' "$1" > "$FIFO"
else
  start_daemon
  case "$1" in
    /*) FILE="$1" ;;
    *) FILE="/System/Library/Sounds/$1.aiff" ;;
  esac
  /usr/bin/afplay "$FILE" >/dev/null 2>&1 &
fi
