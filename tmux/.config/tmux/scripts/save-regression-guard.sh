#!/usr/bin/env bash
# Post-save hook: detect if the resurrect save we just wrote captured
# dramatically less state than recent history. If so, sideline it (rename to
# *-regressed.txt) and repoint "last" at the previous valid save. This makes
# the resurrect chain self-healing: even if continuum fires a save during a
# brief state collapse, the bad save can't stick as the restore source.
#
# Notifies via Mako (notify-send) so the user knows a regression was detected.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Library: re-use is_valid / is_structurally_valid / pane_count / find_latest_valid
# and the RESURRECT_DIR / LAST_LINK / threshold vars defined in resurrect-guard.sh
# shellcheck source=/dev/null
source "$SCRIPT_DIR/resurrect-guard.sh"

LOG_TAG="save-regression-guard"

# Identify the file that was just saved (last symlink target).
[ -L "$LAST_LINK" ] || exit 0
target="$(readlink "$LAST_LINK")"
target_path="$RESURRECT_DIR/$target"

# Structurally invalid is handled by the pre-restore guard at next restore.
# We only need to act on regression — the case where the file is valid in shape
# but captures dramatically less state than recent saves.
if ! is_structurally_valid "$target_path"; then
    exit 0
fi

candidate_panes=$(pane_count "$target_path")
high_water=$(recent_high_water_mark "$target_path")

# No prior history → nothing to compare against, keep the save.
[ "$high_water" -eq 0 ] && exit 0

threshold_panes=$(( high_water * REGRESSION_THRESHOLD_PERCENT / 100 ))
if [ "$candidate_panes" -ge "$threshold_panes" ]; then
    exit 0
fi

# Regressed — sideline the file and repoint last to the previous valid save.
regressed="${target_path%.txt}-regressed.txt"
mv "$target_path" "$regressed"
# Also rename the conda sidecar if save-conda-envs.sh wrote one.
[ -f "${target_path%.txt}-conda.txt" ] \
    && mv "${target_path%.txt}-conda.txt" "${regressed%.txt}-conda.txt"

rm -f "$LAST_LINK"
previous="$(find_latest_valid)"
if [ -n "$previous" ]; then
    ln -s "$(basename "$previous")" "$LAST_LINK"
    repoint_msg="repointed last -> $(basename "$previous")"
else
    repoint_msg="no valid previous save found; last symlink removed"
fi

echo "$LOG_TAG: regressed save ${candidate_panes} panes vs HWM ${high_water} (threshold ${REGRESSION_THRESHOLD_PERCENT}%); $repoint_msg" >&2

# Best-effort notification — use the same pattern as claude-notify (Mako).
if command -v notify-send >/dev/null 2>&1; then
    notify-send -u critical -t 0 -a "tmux-resurrect" \
        "tmux state collapse blocked" \
        "Save captured ${candidate_panes} panes (vs HWM ${high_water}). Sidelined to $(basename "$regressed"). ${repoint_msg}." \
        2>/dev/null || true
fi
