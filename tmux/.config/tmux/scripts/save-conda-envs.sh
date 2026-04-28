#!/usr/bin/env bash
# Post-save hook: write per-pane conda/mamba env to a sidecar file.
# The sidecar is named after the resurrect file so restore-conda-envs.sh
# can find the matching snapshot.
RESURRECT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect"
LAST=$(readlink -f "$RESURRECT_DIR/last" 2>/dev/null) || exit 0
SIDECAR="${LAST%.txt}-conda.txt"

tmux list-panes -a -F '#{pane_id} #{@conda_env}' 2>/dev/null \
    | grep -v ' $' \
    > "$SIDECAR"
