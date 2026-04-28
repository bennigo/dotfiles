#!/usr/bin/env bash
# Post-restore hook: activate conda/mamba env in each pane that had one.
# Reads the sidecar written by save-conda-envs.sh for the current snapshot.
RESURRECT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect"
LAST=$(readlink -f "$RESURRECT_DIR/last" 2>/dev/null) || exit 0
SIDECAR="${LAST%.txt}-conda.txt"
[[ -f "$SIDECAR" ]] || exit 0

while IFS=' ' read -r pane_id env_name; do
    [[ -n "$env_name" ]] || continue
    tmux send-keys -t "$pane_id" "mamba activate $env_name" Enter 2>/dev/null || true
done < "$SIDECAR"
