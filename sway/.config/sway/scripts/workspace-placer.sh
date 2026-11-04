#!/bin/bash
# workspace-placer.sh — put NEWLY created workspaces on the screen the active
# kanshi profile wants (run by workspace-placer.service).
#
# Why this exists: sway APPENDS runtime `workspace N output …` rules to the
# static ones from sway/config instead of replacing them (verified 2026-11-04),
# and the first available output in the list wins — so a profile can never
# override the config's `workspace 7 output eDP-1` for workspaces created later
# (GIMP/Obsidian opened after docking). workspace-layout.sh moves workspaces that
# already exist and writes the map; this listener handles the ones created after.
#
# Map: $XDG_RUNTIME_DIR/sway-workspace-outputs — lines "<workspace> <output>".
# No map (laptop / other profiles) → do nothing; sway/config rules apply.
set -uo pipefail

map="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/sway-workspace-outputs"

swaymsg -m -t subscribe '["workspace"]' |
    jq --unbuffered -r 'select(.change == "init") | .current.name' |
    while read -r ws; do
        [[ -r $map ]] || continue
        want=$(awk -v w="$ws" '$1 == w { print $2 }' "$map")
        [[ -n $want ]] || continue
        state=$(swaymsg -t get_workspaces -r)
        have=$(jq -r --arg w "$ws" '.[] | select(.name == $w) | .output' <<<"$state")
        focused=$(jq -r '.[] | select(.focused) | .name' <<<"$state")
        jq -e --arg o "$want" '.[] | select(.name == $o)' <<<"$(swaymsg -t get_outputs -r)" >/dev/null || continue
        [[ -n $have && $have != "$want" ]] || continue
        # `move workspace` acts on the focused workspace: visit, move, come back.
        back="workspace number $focused"
        [[ $focused == "$ws" ]] && back="workspace number $ws"
        swaymsg -q "workspace number $ws; move workspace to output $want; $back"
    done
