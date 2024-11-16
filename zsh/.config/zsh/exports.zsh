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
export ZDOTDIR=~/.config/zsh


#export PATH="$PATH:./node_modules/.bin"
#source <(fzf --zsh)
eval "$(fnm env)"
eval "$(zoxide init zsh)"
eval `pip completion --zsh`
