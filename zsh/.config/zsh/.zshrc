#sudo apt install -y gpgsudo apt install -y gpg!/bin/sh
# Created by Zap installer
[ -f "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh" ] && source "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh"

# history
HISTFILE="$HOME/.config/zsh/zsh_history"

# source
plug "$HOME/.config/zsh/aliases.zsh"
plug "$HOME/.config/zsh/exports.zsh"

# plugins
plug "esc/conda-zsh-completion"
plug "zsh-users/zsh-autosuggestions"
plug "hlissner/zsh-autopair"
plug "zap-zsh/supercharge"
plug "zap-zsh/vim"
plug "zap-zsh/zap-prompt"
plug "zap-zsh/fzf"
# plug "zap-zsh/exa"
plug "zsh-users/zsh-syntax-highlighting"

export PATH="$HOME/bin:$HOME/.local/bin":$PATH

# keybinds
bindkey '^ ' autosuggest-accept

bindkey -s "^h" "tmux-sessionizer ~/\n"
bindkey -s "^f" "tmux-sessionizer\n"
bindkey -s "^l" "tmux-cht\n"

if command -v batcat &>/dev/null; then
	alias cat="batcat -pp --theme \"Visual Studio Dark+\""
	alias catt="batcat --theme \"Visual Studio Dark+\""
fi

alias less="less -R"
# alias vim="nvim"

# Load and initialise completion system
autoload -Uz compinit
compinit

# echo "TEST"
export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

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

if [ -f "/home/bgo/.local/share/miniforge3/etc/profile.d/mamba.sh" ]; then
    . "/home/bgo/.local/share/miniforge3/etc/profile.d/mamba.sh"
fi
# <<< conda initialize <<<

