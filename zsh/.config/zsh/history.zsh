#!/usr/bin/env zsh
# Shell history configuration.
#
# Sourced at the END of .zshrc (after every `plug` call) because the
# zap-zsh/supercharge plugin sets HISTFILE/HISTSIZE/SAVEHIST when it loads and
# would otherwise silently override these values.
#
# Already-running shells can adopt these settings with `reload-history`.
# Each shell reads the shared history at startup, then keeps its own view.

HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
HISTSIZE=1000000
SAVEHIST=1000000

# Explicitly clear inherited/plugin settings, including on reload. These
# options conflict with INC_APPEND_HISTORY; SHARE_HISTORY also imports other
# shells' commands at each prompt, which would break session-local history.
unsetopt SHARE_HISTORY INC_APPEND_HISTORY_TIME
setopt APPEND_HISTORY         # merge this shell's history into HISTFILE on exit
setopt INC_APPEND_HISTORY     # save immediately, without importing other shells
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

# Apply settings without importing other shells' commands. Only a new shell
# loads the full saved history; reloading must preserve this shell's own view.
reload-history() {
  source "${ZDOTDIR:-$HOME/.config/zsh}/history.zsh"
}
