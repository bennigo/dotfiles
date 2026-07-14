#!/bin/bash
# waybar-top-launcher — thin bar for workspaces + language + power toggles.
#
# Also clears any stray mini bar. The mini bar (config-mini) exists ONLY while
# the top bar is hidden. Because the top bar is a sway `bar { swaybar_command }`
# block, every `swaymsg reload` relaunches it fresh + visible, but does NOT kill
# the separately-spawned mini — so a reload while in "mini mode" left both bars
# showing. Killing the mini here guarantees the invariant (top visible => no
# mini) is restored on every (re)launch, including reloads.
pkill -f 'config-mini.jsonc' 2>/dev/null
exec waybar -c ~/.dotfiles/waybar/.config/waybar/config-top.jsonc \
            -s ~/.dotfiles/waybar/.config/waybar/style-top.css
