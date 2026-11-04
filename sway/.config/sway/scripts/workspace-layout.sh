#!/bin/bash
# workspace-layout.sh — put workspaces on the screens of the active kanshi
# profile. Called from kanshi profile `exec` lines (kanshi/.config/kanshi/config).
# Usage: workspace-layout.sh <work|default>
#
# 1. Moves workspaces that already exist onto their screen (focus returns to
#    the workspace you were on).
# 2. Writes $XDG_RUNTIME_DIR/sway-workspace-outputs ("<ws> <output>") for
#    workspace-placer.sh, which places workspaces CREATED LATER. It does NOT
#    send `workspace N output …` rules: sway appends those to the static ones in
#    sway/config instead of replacing them, so they can never override them
#    (verified 2026-11-04). "default" removes the map → sway/config rules apply.
# 3. Writes the scratchpad target screens used by ~/.local/bin/sway-scratch.
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
        for ws in 1 3 9 10; do rules[$ws]=$laptop; done
        rules[2]="$centre $laptop"         # work Firefox (assign → workspace 2)
        rules[8]="$centre $laptop"         # QGIS (assign → workspace 8)
        rules[5]="${left:+$left }$centre $laptop"
        rules[4]="${right:+$right }$laptop"
        rules[6]="${right:+$right }$laptop"    # GIMP (assign → workspace 6)
        rules[7]="${right:+$right }$laptop"    # Obsidian (assign → workspace 7)
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

# First active output in each rule = where that workspace belongs now.
declare -A place
for ws in "${!rules[@]}"; do
    for out in ${rules[$ws]}; do
        if grep -qx "$out" <<<"$active"; then place[$ws]=$out; break; fi
    done
done

cmds=()
# Move open workspaces to their output.
while read -r ws current; do
    out=${place[$ws]:-}
    [[ -n $out && $out != "$current" ]] && cmds+=("workspace number $ws" "move workspace to output $out")
done <<<"$open"

cmds+=("workspace number $focused")

# Scratchpad target screens for ~/.local/bin/sway-scratch (pdf = Zathura,
# term = floating terminal, other = every other scratchpad window).
# No file = plain `scratchpad show`.
run=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
targets="$run/sway-scratch-targets"
wsmap="$run/sway-workspace-outputs"
if [[ "$1" == work ]]; then
    printf 'pdf %s\nterm %s\nother %s\n' "$left" "$laptop" "${right:-$centre}" >"$targets"
    for ws in "${!place[@]}"; do echo "$ws ${place[$ws]}"; done | sort -n >"$wsmap"
else
    rm -f "$targets" "$wsmap"
fi
swaymsg -q "$(IFS=';'; echo "${cmds[*]}")"
