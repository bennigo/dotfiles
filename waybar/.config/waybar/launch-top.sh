#!/bin/bash
# waybar-top-launcher — thin bar for workspaces + language + power toggles
exec waybar -c ~/.dotfiles/waybar/.config/waybar/config-top.jsonc \
            -s ~/.dotfiles/waybar/.config/waybar/style-top.css
