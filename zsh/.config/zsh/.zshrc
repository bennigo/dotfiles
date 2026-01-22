#!/bin/zsh
# Zsh configuration

# Load Zap plugin manager
[ -f "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh" ] && source "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh"

# History configuration
HISTFILE="$HOME/.config/zsh/zsh_history"
HISTSIZE=1000000
SAVEHIST=1000000

# Source custom configurations
plug "$HOME/.config/zsh/aliases.zsh"
plug "$HOME/.config/zsh/exports.zsh"
# Fallback if plug doesn't work
[ -f "$HOME/.config/zsh/exports.zsh" ] && source "$HOME/.config/zsh/exports.zsh"

# Zap plugins
plug "zsh-users/zsh-autosuggestions"
plug "zap-zsh/supercharge"
plug "zap-zsh/vim"
plug "zap-zsh/zap-prompt"
plug "zap-zsh/fzf"
plug "zap-zsh/exa"
plug "zsh-users/zsh-syntax-highlighting"
plug "hlissner/zsh-autopair"
plug "urbainvaes/fzf-marks"
plug "esc/conda-zsh-completion"

# Load and initialise completion system
autoload -Uz compinit && compinit

# Cargo (Rust) environment
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# FNM (Node.js) environment
FNM_PATH="$HOME/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "$(fnm env --use-on-cd)"
fi

# NPM global packages
NPM_PATH="$HOME/.local/share/npm-global/bin"
[ -d "$NPM_PATH" ] && export PATH="$NPM_PATH:$PATH"

# FZF configuration
if [[ ! "$PATH" == */.local/share/fzf/bin* ]]; then
  [ -d "$HOME/.local/share/fzf/bin" ] && export PATH="${PATH:+${PATH}:}$HOME/.local/share/fzf/bin"
fi
[ -f "$HOME/.fzf.zsh" ] && source "$HOME/.fzf.zsh"
command -v fzf >/dev/null 2>&1 && source <(fzf --zsh 2>/dev/null)

# fzf-marks configuration
export FZF_MARKS_FILE="${HOME}/.fzf-marks"
export FZF_MARKS_COMMAND="fzf --height 40% --reverse"

# Grim screenshot configuration
[ -f "$HOME/.config/grim/config.sh" ] && source "$HOME/.config/grim/config.sh"

# Keybinds
bindkey '^ ' autosuggest-accept
bindkey -s "^h" "tmux-sessionizer ~/\n"
bindkey -s "^f" "tmux-sessionizer\n"
bindkey -s "^l" "tmux-cht\n"

# Aliases
if command -v bat &>/dev/null; then
  alias cat="bat -pp --theme \"Visual Studio Dark+\""
  alias catt="bat --theme \"Visual Studio Dark+\""
fi
alias less="less -R"

# NVM (legacy, prefer fnm)
export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"


# Conda alias (use mamba instead)
alias conda="mamba"

# Additional custom aliases
[ -f "$HOME/.config/zsh/aliases-sync.zsh" ] && source "$HOME/.config/zsh/aliases-sync.zsh"
# >>> mamba initialize >>>
# !! Contents within this block are managed by 'mamba shell init' !!
export MAMBA_EXE='/home/bgo/.miniforge/bin/mamba';
export MAMBA_ROOT_PREFIX='/home/bgo/.miniforge';
__mamba_setup="$("$MAMBA_EXE" shell hook --shell zsh --root-prefix "$MAMBA_ROOT_PREFIX" 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__mamba_setup"
else
    alias mamba="$MAMBA_EXE"  # Fallback on help from mamba activate
fi
unset __mamba_setup
# <<< mamba initialize <<<
