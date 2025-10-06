# Dotfiles and Password Store Sync Aliases
# Convenient shortcuts for keeping configurations synchronized

# Main sync commands
alias sync='dotfiles-sync'
alias sync-all='dotfiles-sync --all'
alias sync-pass='dotfiles-sync --pass-only'
alias sync-dotfiles='dotfiles-sync --dotfiles-only'
alias sync-claude='dotfiles-sync --claude-only'

# Status checks
alias sync-status='dotfiles-sync --status'
alias sync-check='dotfiles-sync --status'

# Preview mode
alias sync-dry='dotfiles-sync --dry-run'
alias sync-preview='dotfiles-sync --dry-run'

# Quick password store operations
alias pass-sync='cd ~/.password-store && git pull --rebase && git push'
alias pass-status='cd ~/.password-store && git status'
alias pass-log='cd ~/.password-store && git log --oneline -10'

# Combined quick sync (all repos)
alias qsync='dotfiles-sync'

# Verbose sync with details
alias vsync='dotfiles-sync --verbose'
