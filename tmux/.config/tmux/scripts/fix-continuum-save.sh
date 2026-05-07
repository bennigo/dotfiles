#!/bin/bash
# Catppuccin unconditionally rewrites status-right (catppuccin.tmux:322), erasing
# the save interpolation that continuum.tmux injects. This script re-prepends it.
# Called via 'run' after tpm so it runs after all plugins have set status-right.
# Idempotent: skips if the interpolation is already present.

save_interp="#($HOME/.config/tmux/plugins/tmux-continuum/scripts/continuum_save.sh)"
current="$(tmux show -gv status-right 2>/dev/null)"

if [[ "$current" != *"continuum_save.sh"* ]]; then
    tmux set -g status-right "${save_interp}${current}"
fi
