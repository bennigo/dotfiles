#!/bin/bash
# waybar-herdr-launcher — tall floating bar for herdr status only.
# Starts HIDDEN by default: waybar comes up visible, then we send one
# SIGUSR1 to hide it. Reveal/hide anytime with `herdr-bars-toggle herdr`
# (Win+Ctrl+q). Sway keeps this script as the bar process, so the toggle's
# `pkill -SIGUSR1 -f config-herdr.jsonc` still targets the running waybar.
waybar -c ~/.dotfiles/waybar/.config/waybar/config-herdr.jsonc \
       -s ~/.dotfiles/waybar/.config/waybar/style-herdr.css &
wb=$!
# once the layer surface exists, hide it (start collapsed by default)
( sleep 1; kill -SIGUSR1 "$wb" 2>/dev/null ) &
wait "$wb"
