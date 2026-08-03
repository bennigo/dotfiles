#!/bin/bash
# waybar-top-launcher — supervised top bar (workspaces + language + power).
#
# Sway runs this script as the bar-0 process. It CANNOT be relied on to keep
# the bar alive: during `swaymsg reload` waybar may start before sway has
# re-advertised the wlr-layer-shell global and die instantly ("compositor
# does not support wlr-layer-shell"), and sway's handling of dead/half-dead
# bar processes is erratic on this machine. So this script SUPERVISES:
# every 5s, if no config-top waybar lives, start one (retrying past the
# layer-shell race) and apply the intended visibility from the state file.
#
# Notes:
#  - SIGUSR1 is a TOGGLE — never spam it (the old retry loop flickered the
#    bar on/off for 15s after every reload).
#  - `kill -0` alone can't detect a dead child (zombies pass it) — check
#    process state and require "Bar configured" in the startup log.
#  - While the bar is alive the supervisor does nothing, so manual toggles
#    (herdr-bars-toggle top, Win+Shift+q) are never fought.
STATE="${XDG_RUNTIME_DIR:-/tmp}/herdr-bars-top.state"
CFG=~/.dotfiles/waybar/.config/waybar/config-top.jsonc
CSS=~/.dotfiles/waybar/.config/waybar/style-top.css
MINI_CFG=~/.config/waybar/config-mini.jsonc
MINI_CSS=~/.config/waybar/style-mini.css

# Single instance: a sway reload may spawn a fresh supervisor without
# reaping the previous one — kill older copies of ourselves (higher PID
# wins, guards below prevent duplicate bars in the meantime).
pgrep -f "$0" 2>/dev/null | while read -r p; do
    [ "$p" != "$$" ] && [ "$p" -lt "$$" ] && kill "$p" 2>/dev/null
done

proc_alive() {  # true if PID $1 is a live, non-zombie process
    local st
    st=$(ps -o stat= -p "$1" 2>/dev/null) || return 1
    case "$st" in *Z*) return 1 ;; esac
    [ -n "$st" ]
}

bar_running() { pgrep -f "$CFG" >/dev/null 2>&1; }

start_bar() {  # start waybar, retrying past the reload layer-shell race
    local log wb
    log=$(mktemp /tmp/waybar-top.XXXXXX.log)
    for _ in $(seq 1 30); do               # ~60s of retries, then give up
        : > "$log"
        waybar -c "$CFG" -s "$CSS" >>"$log" 2>&1 &
        wb=$!
        sleep 1.5                           # the race kills waybar in ~80ms
        if proc_alive "$wb" && grep -q "Bar configured" "$log"; then
            rm -f "$log"
            return 0
        fi
        wait "$wb" 2>/dev/null              # reap the dead attempt
        sleep 1
    done
    rm -f "$log"
    return 1
}

apply_state() {  # enforce hidden/visible + mini inverse after a (re)start
    if [ "$(cat "$STATE" 2>/dev/null)" = hidden ]; then
        pkill -SIGUSR1 -f "$CFG"            # hide exactly once
        pgrep -f "$MINI_CFG" >/dev/null 2>&1 || \
            waybar -c "$MINI_CFG" -s "$MINI_CSS" >/dev/null 2>&1 &
    else
        pkill -f "$MINI_CFG" 2>/dev/null    # top visible -> no mini
    fi
}

while true; do
    if ! bar_running; then
        start_bar && apply_state
    fi
    sleep 5
done
