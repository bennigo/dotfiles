# Set ZDOTDIR to use XDG-compliant zsh config location
export ZDOTDIR="${HOME}/.config/zsh"

# Source cargo environment if it exists
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
