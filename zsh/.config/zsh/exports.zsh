#!/bin/sh
# History is configured at the END of .zshrc (after plugins). The supercharge
# plugin overrides any HIST* variable set here, so do NOT set history
# variables in this file — they would be silently ignored.
export EDITOR="nvim"
export TERMINAL="foot"
# export BROWSER="qutebrowser"
export BROWSER="firefox"

# Base PATH - must come first
export PATH="$HOME/bin:$HOME/.local/bin:$PATH"
export PATH="/home/bgo/.local/share/fnm:$PATH"
export MANPAGER='nvim +Man!'
export MANWIDTH=999
export PATH=$HOME/.cargo/bin:$PATH
export PATH=$HOME/.local/share/go/bin:$PATH
export GOPATH=$HOME/.local/share/go
export PATH=$HOME/.fnm:$PATH
export PATH="$HOME/.local/share/neovim/bin":$PATH
export PATH="$HOME/.cargo/bin":$PATH
export PATH="/usr/local/go/bin":$PATH
export PATH="/usr/local/rxtools/bin":$PATH
export PATH="/home/bgo/.PRIDE_PPPAR_BIN":$PATH
# GMT (Generic Mapping Tools) — built from source in ~/git/gmt (deployed by the
# ansible `development` role, tag: gmt). GSHHG/DCW coastal data and the GIS libs
# (GDAL/GEOS/PROJ/netCDF/FFTW) are installed under the prefix's share/ and lib/.
# GMT_LIBRARY_PATH is how pygmt (editable in ~/git/pygmt) locates libgmt.so.
export PATH="$HOME/git/gmt/install/bin:$PATH"
export GMT_LIBRARY_PATH="$HOME/git/gmt/install/lib"
export XDG_CURRENT_DESKTOP="Wayland"
export NVM_DIR="$HOME/.config//nvm"
export ZDOTDIR="${HOME}/.config/zsh"
export SWAY_SCREENSHOT_DIR="${HOME}/Pictures/Screenshots"
export GRIM_DEFAULT_DIR="${HOME}/Pictures/Screenshots"
export GRIM_DEFAULT_QUALITY=90

# Pi Coding Agent — override non-XDG defaults (~/.pi/agent)
export PI_CODING_AGENT_DIR="${HOME}/.config/pi/agent"
export PI_CODING_AGENT_SESSION_DIR="${HOME}/.local/share/pi/sessions"

# Add miniforge3 bin to PATH for mamba/conda
export PATH="$HOME/.local/share/miniforge3/bin:$PATH"

# Add Deno to PATH
export PATH="$HOME/.deno/bin:$PATH"

# Add Flatpak applications to PATH
export PATH="/var/lib/flatpak/exports/bin:$PATH"

#export PATH="$PATH:./node_modules/.bin"
#source <(fzf --zsh)
command -v fnm >/dev/null 2>&1 && eval "$(fnm env)"
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"
# pip completion deferred — 110ms startup cost, rarely needed interactively
# Run: eval "$(pip completion --zsh)" if you want tab completion for pip

# API keys from pass — now in .zshenv so they're available to all zsh instances
# (Pi, Crush, Claude Code all need these when launched from non-interactive contexts)

# PostgreSQL connection URL builder from ~/.pgpass
function pg_url() {
  local host=$1
  local db=$2
  [[ ! -f ~/.pgpass ]] && return
  # Match host in field 1, then accept exact db or wildcard (*) in field 3
  local line=$(awk -F: -v h="$host" -v d="$db" \
    '$1 == h && ($3 == d || $3 == "*") {print; exit}' ~/.pgpass)
  if [[ -n "$line" ]]; then
    IFS=':' read -r h p _ u pw <<< "$line"
    echo "postgresql://${u}:${pw}@${h}:${p}/${db}"
  fi
}

# Only set database URLs if .pgpass exists
if [[ -f ~/.pgpass ]]; then
  # Local database - WRITE access
  export LOCAL_POSTGRES_URL=$(pg_url "localhost" "bgo")

  # Production read-only databases
  export PROD_GAS_URL=$(pg_url "pgread.vedur.is" "gas")
  export PROD_SKJALFTALISA_URL=$(pg_url "pgread.vedur.is" "skjalftalisa")
  export PROD_TOS_URL=$(pg_url "pgread.vedur.is" "tos")

  # Development databases - READ ONLY (treat as production)
  export DEV_EPOS_URL=$(pg_url "pgdev.vedur.is" "epos")
  export DEV_GNSS_URL=$(pg_url "pgdev.vedur.is" "gnss-europe-v0-2-9")
  export DEV_METRICS_URL=$(pg_url "pgdev.vedur.is" "gps_metrics")
  export GPS_HEALTH_DEV_URL=$(pg_url "pgdev.vedur.is" "gps_health")
  export GPS_HEALTH_LOCAL_URL=$(pg_url "localhost" "gps_health")
fi

# NOTE: hooks in this file register with a remove-then-add rather than a bare
# `+=`. .zshrc sources this file TWICE (line 13 `plug`, line 15 `source`), so a
# bare `+=` registers a hook twice and it then runs twice per prompt.
# Remove-then-add makes every hook here idempotent regardless of how many times
# the file is sourced.
#
# Retired 2026-09-23 with tmux: a `refresh-wayland-env` / `refresh-shell-env`
# pair, the `_auto_refresh_wayland_precmd` hook that retried it each prompt, and
# `_tmux_track_conda` (which forked `tmux set-option` on EVERY prompt to record
# the conda env in a pane option for the resurrect hooks). All three were guarded
# on `$TMUX` and therefore already inert. herdr panes inherit the graphical
# environment from the server that launched them, so there is nothing to refresh,
# and `_mamba_autoenv` below replaces the pane-option tracking outright. See
# systemd/CLAUDE.md → "herdr persistence".

# ── mamba/conda activation by directory ──────────────────────────────────────
# Activate the env named in a `.mamba-env` file found in the current directory or
# any parent. This is what makes a mamba env survive a herdr restart: herdr
# brings each pane back in its saved cwd, so the shell re-activates by itself —
# no per-pane state to snapshot and no timing race against the restore.
#
#     echo gpslibrary > ~/work/projects/gpslibrary/.mamba-env
#
# Only an env this hook activated is deactivated on leaving; one you activated
# by hand is left alone. Set MAMBA_AUTOENV=0 to disable.
_mamba_autoenv() {
    [[ -o interactive ]] || return 0
    [[ "${MAMBA_AUTOENV:-1}" == "1" ]] || return 0
    # Requires the `mamba` shell function from .zshrc's `mamba shell init` block;
    # the bare binary cannot modify the parent shell's environment.
    (( $+functions[mamba] )) || return 0

    local dir=$PWD want=""
    while true; do
        if [[ -r "$dir/.mamba-env" ]]; then
            read -r want < "$dir/.mamba-env" || want=""
            want=${want//[[:space:]]/}
            break
        fi
        [[ "$dir" == "/" ]] && break
        dir=${dir:h}
    done

    local current="${CONDA_DEFAULT_ENV:-}"
    [[ "$current" == "base" ]] && current=""

    if [[ -n "$want" ]]; then
        [[ "$want" == "$current" ]] && return 0
        if mamba activate "$want" 2>/dev/null; then
            _MAMBA_AUTOENV_OWNED="$want"
        else
            print -u2 "mamba-autoenv: cannot activate '$want' (from $dir/.mamba-env)"
            _MAMBA_AUTOENV_OWNED=""
        fi
    elif [[ -n "$current" && "$current" == "${_MAMBA_AUTOENV_OWNED:-}" ]]; then
        mamba deactivate 2>/dev/null || true
        _MAMBA_AUTOENV_OWNED=""
    fi
}
chpwd_functions=(${chpwd_functions:#_mamba_autoenv})
chpwd_functions+=(_mamba_autoenv)

# First run at shell start, deferred until the mamba shell hook exists (.zshrc
# initialises mamba *after* sourcing this file, so calling it inline would be a
# silent no-op). Self-removing, so there is no per-prompt cost afterwards. This
# deferred first run is what re-activates the env in a herdr-restored pane.
_mamba_autoenv_boot() {
    (( $+functions[mamba] )) || return 0
    precmd_functions=(${precmd_functions:#_mamba_autoenv_boot})
    unfunction _mamba_autoenv_boot 2>/dev/null
    _mamba_autoenv
}
precmd_functions=(${precmd_functions:#_mamba_autoenv_boot})
precmd_functions+=(_mamba_autoenv_boot)
