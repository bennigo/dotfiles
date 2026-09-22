export ZDOTDIR="${HOME}/.config/zsh"

. "$HOME/.cargo/env"

. "$HOME/.local/bin/env"

# fzf lives in a git-install directory that ONLY the interactive .zshrc adds
# ($ZDOTDIR/.zshrc — "FZF path (must be set before plugins that depend on fzf)").
#
# This file is the one NON-INTERACTIVE consumers read, and they never see
# .zshrc: systemd user services run through `zsh -lc` (herdr.service being the
# one that matters), and herdr runs every [[keys.command]] popup in a shell
# that is not interactive either. With no fzf on PATH, herdr-sessionx still
# exits 0 — it just does nothing in ~40 ms — so `ctrl+a o` looked like
# "a popup flashes open and closes instantly" (2026-09-22, after herdr.service
# moved to WantedBy=default.target and therefore began starting from systemd
# instead of from a hand-launched terminal with the full interactive PATH).
#
# Keep this guarded: `zsh -lic` reaches the same directory through .zshrc, and
# duplicate PATH entries are what make `zsh -lic`'s PATH 87 entries long.
if [[ ! "$PATH" == */.local/share/fzf/bin* ]]; then
    [ -d "$HOME/.local/share/fzf/bin" ] && export PATH="${PATH:+${PATH}:}$HOME/.local/share/fzf/bin"
fi

# API keys from pass — loaded ONCE at login via ~/.profile (see api-keys.sh),
# then inherited by every shell. Fallback-loaded here only when absent (SSH/
# tty, or if the login-time decryption failed before gpg-agent was unlocked).
# Kept out of .zshenv's per-shell path because the ~11 gpg decryptions added
# ~3s to every prompt (and far more at boot while the GPG key was locked).
. "$HOME/.config/zsh/api-keys.sh"
