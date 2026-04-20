#!/usr/bin/env bash
# corner-clock.sh — toggle a live, per-second clock overlay pinned to the
# upper-right corner. Content mirrors show-time-gps.sh (time, date, ISO/GPS
# week, DOY) but refreshes every second for as long as it's toggled on.
#
# Usage:
#   corner-clock.sh          # Toggle on if off, off if on.
#   corner-clock.sh --stop   # Force-stop an existing instance (no-op if none).
#   corner-clock.sh --status # Print "running <pid>" or "stopped" and exit.
#
# Implementation:
#   - Uses notify-send with app-name=sway-overlay-corner so Mako routes to
#     the compact top-right rule in ~/.config/mako/config.
#   - The x-canonical-private-synchronous hint makes each 1s refresh replace
#     the prior notification in-place (no queue pile-up, no audio spam).
#   - A PID file in $XDG_RUNTIME_DIR tracks the background loop so a second
#     invocation of the keybinding dismisses the overlay and kills the loop.

set -euo pipefail

APP_NAME="sway-overlay-corner"
SYNC_TAG="corner-clock"
PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/corner-clock.pid"

# --- GPS epoch: 1980-01-06 00:00:00 UTC, in Unix seconds.
GPS_EPOCH=315964800

dismiss_overlay() {
  command -v makoctl >/dev/null 2>&1 || return 0
  command -v jq      >/dev/null 2>&1 || return 0
  local id
  id="$(makoctl list 2>/dev/null \
    | jq -r --arg app "$APP_NAME" \
        '[.data[0][]? | select(."app-name".data == $app) | .id.data] | first // empty' \
    2>/dev/null || true)"
  [[ -n "$id" ]] && makoctl dismiss -n "$id" >/dev/null 2>&1 || true
}

running_pid() {
  [[ -f "$PIDFILE" ]] || return 1
  local pid
  pid="$(cat "$PIDFILE" 2>/dev/null || true)"
  [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null && { echo "$pid"; return 0; }
  rm -f "$PIDFILE"
  return 1
}

stop_instance() {
  local pid
  if pid="$(running_pid)"; then
    kill "$pid" 2>/dev/null || true
    # Give the loop a beat to exit its trap, then force-kill if still alive.
    for _ in 1 2 3; do
      kill -0 "$pid" 2>/dev/null || break
      sleep 0.05
    done
    kill -0 "$pid" 2>/dev/null && kill -9 "$pid" 2>/dev/null || true
  fi
  rm -f "$PIDFILE"
  dismiss_overlay
}

tick_once() {
  local time date isowk doy now_utc gpswk
  time="$(date +%H:%M:%S)"
  date="$(date +%Y-%m-%d)"
  isowk="$(date +%V)"
  doy="$(date +%j)"
  now_utc="$(date -u +%s)"
  gpswk=$(( (now_utc - GPS_EPOCH) / 604800 ))

  # -t 2000 (not -t 0): this Mako treats 0 as "expire immediately".
  # 2s is comfortably longer than the 1s refresh interval, so the bubble
  # stays visible during normal operation and self-dismisses ~2s after the
  # last tick if the daemon is killed abruptly.
  notify-send \
    -a "$APP_NAME" \
    -t 2000 \
    -h "string:x-canonical-private-synchronous:$SYNC_TAG" \
    "🕒 ${time}   📅 ${date}" \
    "<span size=\"150%\">Wk ${isowk}   •   GPS ${gpswk}   •   DOY ${doy}</span>"
}

run_loop() {
  trap 'dismiss_overlay; exit 0' TERM INT HUP
  while :; do
    tick_once || true
    # Align the next tick to the following wall-clock second so the
    # displayed HH:MM:SS doesn't visibly lag.
    local frac
    frac="$(date +%N 2>/dev/null || echo 0)"
    # %N may have leading zeros; strip and clamp to 9 digits.
    frac="${frac#"${frac%%[!0]*}"}"
    [[ -z "$frac" ]] && frac=0
    sleep "$(awk -v n="$frac" 'BEGIN{s=(1000000000-n)/1000000000; if(s<=0||s>1)s=1; printf "%.3f",s}')"
  done
}

case "${1:-toggle}" in
  --stop)
    stop_instance
    exit 0
    ;;
  --status)
    if pid="$(running_pid)"; then
      echo "running $pid"
    else
      echo "stopped"
    fi
    exit 0
    ;;
  toggle|"")
    if running_pid >/dev/null; then
      stop_instance
      exit 0
    fi
    # Start the refresh loop detached from this shell so the keybinding
    # invocation returns immediately.
    ( run_loop ) &
    echo $! > "$PIDFILE"
    disown || true
    exit 0
    ;;
  -h|--help)
    sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'
    exit 0
    ;;
  *)
    echo "error: unknown argument: $1" >&2
    exit 2
    ;;
esac
