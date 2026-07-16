#!/bin/bash
# waybar-top-launcher — thin bar for workspaces + language + power toggles.
#
# On restart (e.g. after Sway reload), waybar comes up VISIBLE. We restore
# the intended visibility from herdr-bars-top.state. The mini bar is the
# inverse of the top bar: shown when top is hidden, killed when top returns.
STATE="${XDG_RUNTIME_DIR:-/tmp}/herdr-bars-top.state"

pkill -f 'config-mini.jsonc' 2>/dev/null

waybar -c ~/.dotfiles/waybar/.config/waybar/config-top.jsonc \
       -s ~/.dotfiles/waybar/.config/waybar/style-top.css &
wb=$!

# If state says hidden, hide the top bar and spawn the mini.
st=$(cat "$STATE" 2>/dev/null)
if [ "$st" = hidden ]; then
    # Wait for waybar's layer surface then hide it.
    (
        for i in $(seq 1 30); do
            sleep 0.5
            kill -SIGUSR1 "$wb" 2>/dev/null || break
        done
    ) &
    # Spawn the mini bar.
    pgrep -f 'config-mini.jsonc' >/dev/null 2>&1 || \
        waybar -c ~/.config/waybar/config-mini.jsonc \
               -s ~/.config/waybar/style-mini.css >/dev/null 2>&1 &
fi

wait "$wb"
