export ZDOTDIR="${HOME}/.config/zsh"

. "$HOME/.cargo/env"

. "$HOME/.local/bin/env"

# API keys from pass — loaded ONCE at login via ~/.profile (see api-keys.sh),
# then inherited by every shell. Fallback-loaded here only when absent (SSH/
# tty, or if the login-time decryption failed before gpg-agent was unlocked).
# Kept out of .zshenv's per-shell path because the ~11 gpg decryptions added
# ~3s to every prompt (and far more at boot while the GPG key was locked).
. "$HOME/.config/zsh/api-keys.sh"
