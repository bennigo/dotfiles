#!/bin/bash
# waybar-herdr-launcher — tall floating bar for herdr status only.
# Starts HIDDEN via "start_hidden": true in config-herdr.jsonc — no signals
# needed at launch. (The old retry loop spammed SIGUSR1 every 0.5s; SIGUSR1
# is a TOGGLE, so the bar flickered on/off for up to 15s after a reload.)
#
# Retry loop, same as launch-top.sh: during `swaymsg reload` waybar can
# start before sway has re-advertised the wlr-layer-shell global and exit
# instantly ("compositor does not support wlr-layer-shell"). Sway never
# respawns dead bar processes, so retry until waybar survives startup.
#
# Reveal/hide anytime with `herdr-bars-toggle herdr` (Win+Ctrl+q).
# Sway keeps this script as the bar process.
CFG=~/.dotfiles/waybar/.config/waybar/config-herdr.jsonc
CSS=~/.dotfiles/waybar/.config/waybar/style-herdr.css

LOG=$(mktemp /tmp/waybar-herdr.XXXXXX.log)
wb=""
for _ in $(seq 1 30); do               # ~60s of retries, then give up
    : > "$LOG"
    waybar -c "$CFG" -s "$CSS" >>"$LOG" 2>&1 &
    wb=$!
    sleep 1.5                           # the layer-shell race kills it in ~80ms
    kill -0 "$wb" 2>/dev/null && break
    wait "$wb" 2>/dev/null
    sleep 1
done
kill -0 "$wb" 2>/dev/null || { rm -f "$LOG"; exit 1; }

wait "$wb"
rm -f "$LOG"
