#!/usr/bin/env bash
# Wrapper for @resurrect-hook-post-save-all.
# Runs the conda-env snapshot first, then the regression guard.
# Each step is best-effort: failures don't block the others.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$SCRIPT_DIR/save-conda-envs.sh" || true
bash "$SCRIPT_DIR/save-regression-guard.sh" || true
