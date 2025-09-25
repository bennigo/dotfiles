#sudo apt install -y gpgsudo apt install -y gpg!/bin/sh
# Created by Zap installer
[ -f "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh" ] && source "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh"

# Load and initialise completion system
# autoload -Uz compinit && compinit

# history
HISTFILE="$HOME/.config/zsh/zsh_history"

# source
plug "$HOME/.config/zsh/aliases.zsh"
plug "$HOME/.config/zsh/exports.zsh"

# [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Setup fzf
# ---------
if [[ ! "$PATH" == */home/bgo/.local/share/fzf/bin* ]]; then
# Created by Zap installer
[ -f "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh" ] && source "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh"
plug "zsh-users/zsh-autosuggestions"
plug "zap-zsh/supercharge"
plug "zap-zsh/zap-prompt"
plug "zsh-users/zsh-syntax-highlighting"

# Load and initialise completion system
autoload -Uz compinit
compinit
export PATH="$HOME/.local/bin:$PATH"
# Cargo (Rust) environment
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
# FNM (Node.js) environment
[[ -f "$HOME/.local/share/fnm/fnm" ]] && eval "$(fnm env --use-on-cd)"
# FZF key bindings
[[ -f "$HOME/.fzf.zsh" ]] && source "$HOME/.fzf.zsh"

. "$HOME/.local/bin/env"
  PATH="${PATH:+${PATH}:}/home/bgo/.local/share/fzf/bin"
  source <(fzf --zsh)

  # Load fzf-marks with explicit path
  source "${HOME}/.local/share/zap/plugins/fzf-marks/fzf-marks.plugin.zsh"
  # Set explicit configuration
  export FZF_MARKS_FILE="${HOME}/.fzf-marks"
  export FZF_MARKS_COMMAND="fzf --height 40% --reverse"
  # export FZF_MARKS_COMMAND="fzf --height 40% --reverse -n 1 -d ' : '"
fi

# set up grim
source ~/.config/grim/config.sh

# plugins
plug "urbainvaes/fzf-marks"
plug "esc/conda-zsh-completion"
plug "zsh-users/zsh-autosuggestions"
plug "hlissner/zsh-autopair"
plug "zap-zsh/supercharge"
plug "zap-zsh/vim"
plug "zap-zsh/zap-prompt"
plug "zap-zsh/fzf"
plug "zap-zsh/exa"
plug "zsh-users/zsh-syntax-highlighting"


export PATH="$HOME/bin:$HOME/.local/bin":$PATH

# keybinds
bindkey '^ ' autosuggest-accept

bindkey -s "^h" "tmux-sessionizer ~/\n"
bindkey -s "^f" "tmux-sessionizer\n"
bindkey -s "^l" "tmux-cht\n"

if command -v bat &>/dev/null; then
	alias cat="bat -pp --theme \"Visual Studio Dark+\""
	alias catt="bat --theme \"Visual Studio Dark+\""
fi

alias less="less -R"
# alias vim="nvim"
#

# Load and initialise completion system
autoload -Uz compinit && compinit

# 
export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# >>> mamba initialize >>>
# !! Contents within this block are managed by 'mamba shell init' !!
export MAMBA_EXE='/home/bgo/.local/share/miniforge3/bin/mamba';
export MAMBA_ROOT_PREFIX='/home/bgo/.local/share/miniforge3';
__mamba_setup="$("$MAMBA_EXE" shell hook --shell zsh --root-prefix "$MAMBA_ROOT_PREFIX" 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__mamba_setup"
else
    alias mamba="$MAMBA_EXE"  # Fallback on help from mamba activate
fi
unset __mamba_setup
# <<< mamba initialize <<<



# fnm
FNM_PATH="$HOME/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "`fnm env`"
fi
# npm
NPM_PATH="$HOME/.local/share/npm-global/bin"
if [ -d "$NPM_PATH" ]; then
  export PATH="$NPM_PATH:$PATH"
  eval "`fnm env`"
fi

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/bgo/.local/share/miniforge3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/bgo/.local/share/miniforge3/etc/profile.d/conda.sh" ]; then
        . "/home/bgo/.local/share/miniforge3/etc/profile.d/conda.sh"
    else
        export PATH="/home/bgo/.local/share/miniforge3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

