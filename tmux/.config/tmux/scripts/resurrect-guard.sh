#!/usr/bin/env bash
# Pre-restore hook for tmux-resurrect.
# Guards against bad resurrection files that would replace good session state:
#   1. Empty / missing files.
#   2. Structurally corrupt files (pane lines without matching window lines —
#      typical of an interrupted save).
#   3. Regressed files — valid structure but dramatically fewer panes than
#      recent history. Catches "state collapse" scenarios where something
#      kills most of the sessions, the next periodic save captures the small
#      state, and that gets restored on reboot.
#
# When the "last" symlink points at a bad file, the guard walks backwards
# through saves (sorted by filename timestamp) and repoints "last" to the
# most recent good file.
#
# The script is also source-able as a library — sourcing it exposes
# is_valid() and find_latest_valid() without executing the guard logic.

RESURRECT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect"
LAST_LINK="$RESURRECT_DIR/last"
LOG_TAG="resurrect-guard"

# Reject saves with <40% the pane count of the recent high-water mark.
# Routine cleanup drops 10–30%; a state collapse drops 70–90%.
REGRESSION_THRESHOLD_PERCENT="${RESURRECT_GUARD_THRESHOLD:-40}"
REGRESSION_HISTORY_DEPTH="${RESURRECT_GUARD_HISTORY:-5}"

# --- helpers ---------------------------------------------------------------

pane_count() {
    local file="$1"
    [ -f "$file" ] || { echo 0; return; }
    grep -c '^pane' "$file" 2>/dev/null || echo 0
}

# Structural integrity check (no regression check). Returns 0 if structurally OK.
is_structurally_valid() {
    local file="$1"

    [ -s "$file" ] || return 1
    grep -q '^pane' "$file" || return 1

    local orphans
    orphans=$(comm -23 \
        <(awk -F'\t' '/^pane/{print $2}' "$file" | LC_ALL=C sort -u) \
        <(awk -F'\t' '/^window/{print $2}' "$file" | LC_ALL=C sort -u))

    [ -z "$orphans" ] || return 1
    return 0
}

# High-water mark of pane counts across the N most recent structurally-valid
# files, EXCLUDING the candidate itself. 0 on first save (no history).
recent_high_water_mark() {
    local exclude="$1"
    local count=0 max=0 pc
    local files
    files=$(ls -1r "$RESURRECT_DIR"/tmux_resurrect_*.txt 2>/dev/null \
        | grep -v -- '-regressed\.txt$' || true)
    while IFS= read -r f; do
        [ -n "$f" ] || continue
        [ "$f" = "$exclude" ] && continue
        is_structurally_valid "$f" || continue
        pc=$(pane_count "$f")
        (( pc > max )) && max=$pc
        (( count++ ))
        (( count >= REGRESSION_HISTORY_DEPTH )) && break
    done <<<"$files"
    echo "$max"
}

# Full validity check: structural + not regressed against recent history.
is_valid() {
    local file="$1"
    is_structurally_valid "$file" || return 1

    local candidate_panes high_water threshold_panes
    candidate_panes=$(pane_count "$file")
    high_water=$(recent_high_water_mark "$file")

    # No history yet → accept whatever we have.
    [ "$high_water" -eq 0 ] && return 0

    threshold_panes=$(( high_water * REGRESSION_THRESHOLD_PERCENT / 100 ))
    if [ "$candidate_panes" -lt "$threshold_panes" ]; then
        return 1
    fi
    return 0
}

# Most recent valid file (skipping anything marked *-regressed).
find_latest_valid() {
    local latest=""
    for f in "$RESURRECT_DIR"/tmux_resurrect_*.txt; do
        [ -f "$f" ] || continue
        case "$f" in *-regressed.txt) continue ;; esac
        if is_valid "$f"; then
            latest="$f"
        fi
    done
    echo "$latest"
}

# --- main ------------------------------------------------------------------

# Sourcing as a library: expose helpers, skip the guard logic.
if [ "${BASH_SOURCE[0]:-$0}" != "$0" ]; then
    return 0 2>/dev/null || true
fi

if [ ! -L "$LAST_LINK" ]; then
    exit 0
fi

target="$(readlink "$LAST_LINK")"
target_path="$RESURRECT_DIR/$target"

if is_valid "$target_path"; then
    exit 0
fi

# Diagnose for the log
if [ ! -s "$target_path" ]; then
    echo "$LOG_TAG: last -> '$target' is empty or missing" >&2
elif ! is_structurally_valid "$target_path"; then
    echo "$LOG_TAG: last -> '$target' is structurally corrupt (pane/window mismatch)" >&2
else
    candidate_panes=$(pane_count "$target_path")
    high_water=$(recent_high_water_mark "$target_path")
    echo "$LOG_TAG: last -> '$target' is regressed (${candidate_panes} panes vs HWM ${high_water}, threshold ${REGRESSION_THRESHOLD_PERCENT}%)" >&2
fi

latest="$(find_latest_valid)"

if [ -z "$latest" ]; then
    echo "$LOG_TAG: no valid resurrection files found, removing last symlink" >&2
    rm -f "$LAST_LINK"
    exit 0
fi

echo "$LOG_TAG: repointing last -> $(basename "$latest")" >&2
rm -f "$LAST_LINK"
ln -s "$(basename "$latest")" "$LAST_LINK"
