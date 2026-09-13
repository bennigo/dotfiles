#!/usr/bin/env zsh
# Shell history configuration.
#
# Sourced at the END of .zshrc (after every `plug` call) because the
# zap-zsh/supercharge plugin sets HISTFILE/HISTSIZE/SAVEHIST when it loads and
# would otherwise silently override these values.
#
# Also sourced by the tmux `prefix + H` binding (tmux.reset.conf) so that
# already-running shells can adopt the settings without a restart.

HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
HISTSIZE=1000000
SAVEHIST=1000000

setopt APPEND_HISTORY         # append to HISTFILE on exit (never truncate)
setopt INC_APPEND_HISTORY     # write each command to HISTFILE immediately
setopt SHARE_HISTORY          # share history live across all shells/tmux panes
setopt EXTENDED_HISTORY       # ":start:elapsed;command" timestamp format
setopt HIST_IGNORE_DUPS       # skip an entry that was just recorded
setopt HIST_IGNORE_ALL_DUPS   # drop the older copy of a repeated command
setopt HIST_IGNORE_SPACE      # don't record commands starting with a space
setopt HIST_FIND_NO_DUPS      # don't show duplicates while searching history
setopt HIST_SAVE_NO_DUPS      # never write duplicates to the file
setopt HIST_REDUCE_BLANKS     # squeeze superfluous blanks
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_VERIFY

# Ensure the history directory exists (XDG state dir)
[[ -d "${HISTFILE:h}" ]] || mkdir -p "${HISTFILE:h}" 2>/dev/null

# Reload this config into an already-running shell and pull in on-disk entries
# from the new location. Invoked by the tmux `prefix + H` binding.
reload-history() {
  source "${ZDOTDIR:-$HOME/.config/zsh}/history.zsh"
  fc -R "$HISTFILE"
}
