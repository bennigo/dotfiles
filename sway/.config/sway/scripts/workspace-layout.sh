#!/bin/bash
# workspace-layout.sh — pin workspaces to outputs for the active kanshi profile
# and move workspaces that are already open onto their output.
#
# Called from kanshi profile `exec` lines (kanshi/.config/kanshi/config).
# Also writes the scratchpad target screens used by ~/.local/bin/sway-scratch.
# Usage: workspace-layout.sh <work|default>
#
# Sway `workspace N output A B …` rules only apply when a workspace is created,
# and kanshi `exec` only runs when a profile changes — so this script does both:
# replace the rules, then move what is already open. Focus returns to the
# workspace you were on.
#
# "default" mirrors the static rules in sway/config (keep the two in sync):
# workspace 5 on the first external, everything else on the laptop panel.
set -euo pipefail

laptop=eDP-1
externals="HDMI-A-1 HDMI-A-2 DP-1 DP-2 DP-3 DP-4 DP-5 DP-6 DVI-I-1 DVI-I-2 DVI-I-3 DVI-I-4"

outputs=$(swaymsg -r -t get_outputs)

declare -A rules
case "${1:?Usage: workspace-layout.sh <work|default>}" in
    work)
        # Left portrait Dell = DP-2, centre HP = HDMI-A-1 (by connector: EDID
        # serials are duplicated at this desk). Right Dell = the remaining
        # active output (a DisplayLink DVI-I-*, whose number shifts with cabling).
        left=DP-2
        centre=HDMI-A-1
        right=$(jq -r --arg l "$left" --arg c "$centre" --arg p "$laptop" \
            '.[] | select(.active and .name != $l and .name != $c and .name != $p) | .name' \
            <<<"$outputs" | head -1)
        for ws in 1 3 6 7 8 9 10; do rules[$ws]=$laptop; done
        rules[2]="$centre $laptop"         # work Firefox (assign → workspace 2)
        rules[5]="${left:+$left }$centre $laptop"
        rules[4]="${right:+$right }$laptop"
        ;;
    default)
        for ws in 1 2 3 4 6 7 8 9 10; do rules[$ws]=$laptop; done
        rules[5]="$externals $laptop"
        ;;
    *)
        echo "workspace-layout.sh: unknown layout '$1'" >&2
        exit 2
        ;;
esac

active=$(jq -r '.[] | select(.active) | .name' <<<"$outputs")
focused=$(swaymsg -r -t get_workspaces | jq -r '.[] | select(.focused) | .name')
open=$(swaymsg -r -t get_workspaces | jq -r '.[] | "\(.name) \(.output)"')

cmds=()
for ws in "${!rules[@]}"; do
    cmds+=("workspace $ws output ${rules[$ws]}")
done

# Move open workspaces to the first active output in their rule.
while read -r ws current; do
    [[ -n "${rules[$ws]:-}" ]] || continue
    for out in ${rules[$ws]}; do
        grep -qx "$out" <<<"$active" || continue
        [[ "$out" == "$current" ]] || cmds+=("workspace number $ws" "move workspace to output $out")
        break
    done
done <<<"$open"

cmds+=("workspace number $focused")

# Scratchpad target screens for ~/.local/bin/sway-scratch (pdf = Zathura,
# other = every other scratchpad window). No file = plain `scratchpad show`.
targets="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/sway-scratch-targets"
if [[ "$1" == work ]]; then
    printf 'pdf %s\nother %s\n' "$left" "${right:-$centre}" >"$targets"
else
    rm -f "$targets"
fi
swaymsg -q "$(IFS=';'; echo "${cmds[*]}")"
