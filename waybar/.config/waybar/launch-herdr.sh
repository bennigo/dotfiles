#!/bin/bash
# waybar-herdr-launcher — tall floating bar for herdr status only
exec waybar -c ~/.dotfiles/waybar/.config/waybar/config-herdr.jsonc \
            -s ~/.dotfiles/waybar/.config/waybar/style-herdr.css
