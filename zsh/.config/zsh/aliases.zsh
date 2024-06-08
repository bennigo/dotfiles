#!/bin/sh
alias j='z'
alias f='zi'
alias g='lazygit'
alias zsh-update-plugins="find "$ZDOTDIR/plugins" -type d -exec test -e '{}/.git' ';' -print0 | xargs -I {} -0 git -C {} pull -q"
alias vrc='nvim ~/.config/nvim/'
alias v='nvim'

# alias lvim='nvim -u ~/.local/share/lunarvim/lvim/init.lua --cmd "set runtimepath+=~/.local/share/lunarvim/lvim"'

# Remarkable
# alias restream='restream -p'

alias rek='TERM=xterm-256color ssh gpsops@rek.vedur.is'
alias okada='TERM=xterm-256color ssh gpsops@okada.vedur.is'
alias sarpur='TERM=xterm-256color ssh gpsops@sarpur.vedur.is'
alias gpsplot='TERM=xterm-256color ssh -X gpsops@gpsplot.vedur.is'
alias rtk='TERM=xterm-256color ssh gpsops@rtk.vedur.is'
alias rplot='TERM=xterm-256color ssh -X gpsops@rplot.vedur.is'
alias strokkur='TERM=xterm-256color ssh bgo@strokkur.raunvis.hi.is'
alias cdn='TERM=xterm-256color ssh gpsops@cdn-p01.vedur.is'
alias insar='TERM=xterm-256color ssh bgo@insar.vedur.is'

# Colorize grep output (good for log files)
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

# confirm before overwriting something
alias cp="cp -i"
alias mv='mv -i'
alias rm='rm -i'

# keep old ls flags
alias le='ls -lsnew'
alias lo='ls -lsold'

# easier to read disk
alias df='df -h'     # human-readable sizes
alias free='free -m' # show sizes in MB

#info with vim keys
alias info='info --vi-keys'

# get top process eating memory
alias psmem='ps auxf | sort -nr -k 4 | head -5'

# get top process eating cpu ##
alias pscpu='ps auxf | sort -nr -k 3 | head -5'

# gpg encryption
# verify signature for isos
# alias gpg-check="gpg2 --keyserver-options auto-key-retrieve --verify"
# receive the key of a developer
# alias gpg-retrieve="gpg2 --keyserver-options auto-key-retrieve --receive-keys"

alias m="git checkout master"
alias s="git checkout stable"
alias config='/usr/bin/git --git-dir=/home/bgo/.cfg/ --work-tree=/home/bgo'

if [[ $TERM == "xterm-kitty" ]]; then
  alias ssh="kitty +kitten ssh"
fi

case "$(uname -s)" in

Darwin)
	# echo 'Mac OS X'
	alias ls='ls -G'
	;;

Linux)
	alias ls='ls --color=auto'
	;;

CYGWIN* | MINGW32* | MSYS* | MINGW*)
	# echo 'MS Windows'
	;;
*)
	# echo 'Other OS'
	;;
esac
