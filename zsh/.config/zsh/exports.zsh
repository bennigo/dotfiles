#!/bin/sh
# HISTFILE="$XDG_DATA_HOME"/zsh/history
HISTSIZE=1000000
SAVEHIST=1000000
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
export XDG_CURRENT_DESKTOP="Wayland"
export NVM_DIR="$HOME/.config//nvm"
export ZDOTDIR="${HOME}/.config/zsh"
export SWAY_SCREENSHOT_DIR="${HOME}/Pictures/Screenshots"
export GRIM_DEFAULT_DIR="${HOME}/Pictures/Screenshots"
export GRIM_DEFAULT_QUALITY=90

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

# API keys from pass - lazy-loaded to avoid ~900ms GPG overhead on every shell
# These are only needed by Claude Code MCP servers, not general shell use.
# Call load-mcp-credentials manually, or they auto-load on first access.
load-mcp-credentials() {
    [[ -n "$_MCP_CREDS_LOADED" ]] && return 0
    export ANTHROPIC_API_KEY=$(pass show tokens/anthropic_api_key 2>/dev/null || echo "")
    export BRAVE_API_KEY=$(pass show tokens/brave_api 2>/dev/null || echo "")
    export GOOGLE_MCP_CLIENT_ID=$(pass show tokens/google_mcp_claude_client_id 2>/dev/null || echo "")
    export GOOGLE_MCP_CLIENT_SECRET=$(pass show tokens/google_mcp_claude_client_secret 2>/dev/null || echo "")
    export _MCP_CREDS_LOADED=1
}

# Auto-load credentials before claude commands
_preexec_load_mcp_creds() {
    if [[ -z "$_MCP_CREDS_LOADED" && ("$1" == claude* || "$1" == crush*) ]]; then
        load-mcp-credentials
    fi
}
autoload -Uz add-zsh-hook
add-zsh-hook preexec _preexec_load_mcp_creds

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
fi

# --- Wayland env refresh for tmux-continuum restored sessions ---
# After reboot, tmux-continuum restores shells before Sway starts,
# leaving WAYLAND_DISPLAY/SWAYSOCK/DISPLAY empty. This pulls current
# values from the tmux session env (populated by update-environment on attach).
refresh-wayland-env() {
    [[ -z "$TMUX" ]] && return 0

    local var val
    for var in WAYLAND_DISPLAY SWAYSOCK DISPLAY; do
        val=$(tmux show-environment "$var" 2>/dev/null)
        case "$val" in
            "$var="*)  export "$val" ;;
            "-$var")   unset "$var" ;;
            *)         ;;
        esac
    done
}

# Auto-refresh Wayland env in tmux (handles continuum-restored shells too).
# A precmd hook retries each prompt until WAYLAND_DISPLAY is set, then
# removes itself so there is zero overhead after the first successful refresh.
_auto_refresh_wayland_precmd() {
    if [[ -z "$WAYLAND_DISPLAY" ]]; then
        refresh-wayland-env
    fi
    if [[ -n "$WAYLAND_DISPLAY" ]]; then
        precmd_functions=(${precmd_functions:#_auto_refresh_wayland_precmd})
        unfunction _auto_refresh_wayland_precmd 2>/dev/null
    fi
}
if [[ -n "$TMUX" && -z "$WAYLAND_DISPLAY" ]]; then
    precmd_functions+=(_auto_refresh_wayland_precmd)
fi
