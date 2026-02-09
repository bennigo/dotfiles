#!/usr/bin/env bash
# Pre-restore hook for tmux-resurrect.
# Guards against empty/corrupt resurrection files that cause tmux to exit
# immediately when continuum tries to auto-restore on startup.
#
# The problem: tmux-resurrect's check_saved_session_exists() only checks if the
# "last" symlink target exists ([ -f ]), not whether it has content ([ -s ]).
# An interrupted save (e.g. tmux dying mid-save) leaves a 0-byte file that
# passes the existence check but gives restore_all_panes nothing to iterate,
# resulting in tmux starting with no sessions and exiting.
#
# This hook runs before any restore and repoints "last" to the most recent
# valid (non-empty) resurrection file.

RESURRECT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect"
LAST_LINK="$RESURRECT_DIR/last"

# Resolve the symlink target
if [ ! -L "$LAST_LINK" ]; then
    exit 0
fi

target="$(readlink "$LAST_LINK")"
target_path="$RESURRECT_DIR/$target"

# Check if the target file has content
if [ -s "$target_path" ]; then
    # File exists and is non-empty, nothing to fix
    exit 0
fi

# Target is empty or missing — find the most recent valid file
echo "resurrect-guard: last points to empty/missing file '$target', searching for valid alternative..." >&2

latest=""
for f in "$RESURRECT_DIR"/tmux_resurrect_*.txt; do
    [ -s "$f" ] || continue
    latest="$f"
done

if [ -z "$latest" ]; then
    echo "resurrect-guard: no valid resurrection files found, removing last symlink" >&2
    rm -f "$LAST_LINK"
    # Remove the empty file too
    [ -f "$target_path" ] && rm -f "$target_path"
    exit 0
fi

echo "resurrect-guard: repointing last -> $(basename "$latest")" >&2
rm -f "$LAST_LINK"
ln -s "$(basename "$latest")" "$LAST_LINK"

# Clean up the empty file
[ -f "$target_path" ] && rm -f "$target_path"
