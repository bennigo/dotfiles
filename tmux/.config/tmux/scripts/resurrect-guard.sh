#!/usr/bin/env bash
# Pre-restore hook for tmux-resurrect.
# Guards against empty AND structurally corrupt resurrection files that cause
# tmux to exit or restore a broken session on startup.
#
# Checks performed on the "last" symlink target:
#   1. File exists and is non-empty (original guard)
#   2. Structural integrity: every session with pane entries must also have
#      at least one window entry. A save interrupted mid-write often drops
#      window lines, leaving panes orphaned. Restoring from such a file
#      produces phantom numbered sessions and loses real ones.
#
# When a problem is detected, the script walks backwards through saved files
# (sorted by filename timestamp) and repoints "last" to the most recent
# structurally valid file.

RESURRECT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect"
LAST_LINK="$RESURRECT_DIR/last"
LOG_TAG="resurrect-guard"

# --- helpers ---------------------------------------------------------------

# Check whether a resurrect file is structurally valid.
# Returns 0 (valid) or 1 (corrupt/empty).
is_valid() {
    local file="$1"

    # Must exist and be non-empty
    [ -s "$file" ] || return 1

    # Must contain at least one pane line (otherwise nothing to restore)
    grep -q '^pane' "$file" || return 1

    # Every session referenced in pane lines must also appear in window lines.
    # An interrupted save typically writes pane lines first, then window lines,
    # so a truncated file has panes without matching windows.
    local orphans
    orphans=$(comm -23 \
        <(awk -F'\t' '/^pane/{print $2}' "$file" | sort -u) \
        <(awk -F'\t' '/^window/{print $2}' "$file" | sort -u))

    [ -z "$orphans" ] || return 1

    return 0
}

# Find the most recent valid file, walking backwards through sorted filenames.
# Prints the path or nothing.
find_latest_valid() {
    local latest=""
    for f in "$RESURRECT_DIR"/tmux_resurrect_*.txt; do
        [ -f "$f" ] || continue
        if is_valid "$f"; then
            latest="$f"
        fi
    done
    echo "$latest"
}

# --- main ------------------------------------------------------------------

# Nothing to do if there is no last symlink
if [ ! -L "$LAST_LINK" ]; then
    exit 0
fi

target="$(readlink "$LAST_LINK")"
target_path="$RESURRECT_DIR/$target"

# Happy path: current target is valid
if is_valid "$target_path"; then
    exit 0
fi

# Diagnose the problem for the log
if [ ! -s "$target_path" ]; then
    echo "$LOG_TAG: last -> '$target' is empty or missing" >&2
else
    echo "$LOG_TAG: last -> '$target' is structurally corrupt (pane/window mismatch)" >&2
fi

# Search for a valid alternative
latest="$(find_latest_valid)"

if [ -z "$latest" ]; then
    echo "$LOG_TAG: no valid resurrection files found, removing last symlink" >&2
    rm -f "$LAST_LINK"
    exit 0
fi

echo "$LOG_TAG: repointing last -> $(basename "$latest")" >&2
rm -f "$LAST_LINK"
ln -s "$(basename "$latest")" "$LAST_LINK"
