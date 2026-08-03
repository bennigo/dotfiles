#!/bin/bash
# waybar-top-launcher — thin bar for workspaces + language + power toggles.
#
# Retry loop: during `swaymsg reload` there is a window where sway has not
# re-advertised the wlr-layer-shell global yet. A waybar starting in that
# window exits instantly ("compositor does not support wlr-layer-shell",
# exit 1 after ~80ms) and sway NEVER respawns a dead bar process — the bar
# is gone until the next reload. So retry until waybar survives startup.
#
# Visibility: waybar comes up VISIBLE on restart; if herdr-bars-top.state
# says hidden, hide it with exactly ONE SIGUSR1 (SIGUSR1 is a toggle — the
# old "spam until it works" loop flickered the bar on/off for 15s) and
# spawn the mini bar (the inverse of the top bar).
STATE="${XDG_RUNTIME_DIR:-/tmp}/herdr-bars-top.state"
CFG=~/.dotfiles/waybar/.config/waybar/config-top.jsonc
CSS=~/.dotfiles/waybar/.config/waybar/style-top.css

pkill -f 'config-mini.jsonc' 2>/dev/null

LOG=$(mktemp /tmp/waybar-top.XXXXXX.log)
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

st=$(cat "$STATE" 2>/dev/null)
if [ "$st" = hidden ]; then
    kill -SIGUSR1 "$wb" 2>/dev/null     # hide exactly once
    pgrep -f 'config-mini.jsonc' >/dev/null 2>&1 || \
        waybar -c ~/.config/waybar/config-mini.jsonc \
               -s ~/.config/waybar/style-mini.css >/dev/null 2>&1 &
fi

wait "$wb"
rm -f "$LOG"
