#!/bin/bash
# waybar-herdr-launcher — tall floating bar for herdr status only.
# Starts HIDDEN by default. Because the layer surface isn't created
# synchronously (especially after GPU resume), we retry the hide signal
# until waybar is ready. Reveal/hide anytime with `herdr-bars-toggle herdr`
# (Win+Ctrl+q). Sway keeps this script as the bar process.
waybar -c ~/.dotfiles/waybar/.config/waybar/config-herdr.jsonc \
       -s ~/.dotfiles/waybar/.config/waybar/style-herdr.css &
wb=$!

# Retry SIGUSR1 until the layer surface exists and the hide takes effect.
# Waybar ignores SIGUSR1 if its output surface isn't registered yet — this
# happens after GPU resume when the compositor needs extra time to
# initialize layer-shell clients.
(
    for i in $(seq 1 30); do
        sleep 0.5
        kill -SIGUSR1 "$wb" 2>/dev/null || break
    done
) &

wait "$wb"
