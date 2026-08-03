#!/bin/bash
# waybar-herdr-launcher — supervised herdr status bar.
# Starts HIDDEN via "start_hidden": true in config-herdr.jsonc — no signals
# needed at launch. (The old retry loop spammed SIGUSR1 every 0.5s; SIGUSR1
# is a TOGGLE, so the bar flickered on/off for up to 15s after a reload.)
#
# Supervised, same as launch-top.sh: during `swaymsg reload` waybar can
# start before sway has re-advertised wlr-layer-shell and die instantly, and
# sway's bar-process handling is erratic here — so check every 5s and
# restart the bar if it is gone. While it lives, the supervisor does
# nothing, so `herdr-bars-toggle herdr` (Win+Ctrl+q) is never fought.
CFG=~/.dotfiles/waybar/.config/waybar/config-herdr.jsonc
CSS=~/.dotfiles/waybar/.config/waybar/style-herdr.css

# Single instance: a sway reload may spawn a fresh supervisor without
# reaping the previous one — kill older copies of ourselves.
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
    log=$(mktemp /tmp/waybar-herdr.XXXXXX.log)
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

while true; do
    bar_running || start_bar
    sleep 5
done
