#!/bin/sh
# HISTFILE="$XDG_DATA_HOME"/zsh/history
HISTSIZE=1000000
SAVEHIST=1000000
export EDITOR="nvim"
export TERMINAL="foot"
# export BROWSER="qutebrowser"
export BROWSER="firefox"
export PATH="$HOME/.local/bin":$PATH
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
export PATH="/opt/Septentrio/RxTools/bin":$PATH
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
eval "$(fnm env)"
eval "$(zoxide init zsh)"
eval `pip completion --zsh`

#API_KEYS and credentials from pass
export BRAVE_API_KEY=$(pass show tokens/brave_api 2>/dev/null || echo "")

  # PostgreSQL connection URL builder from ~/.pgpass
  function pg_url() {
    local host=$1
    local db=$2
    local line=$(grep "^${host}:" ~/.pgpass | grep ":${db}:")
    if [[ -n "$line" ]]; then
      IFS=':' read -r h p d u pw <<< "$line"
      echo "postgresql://${u}:${pw}@${h}:${p}/${d}"
    fi
  }

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
