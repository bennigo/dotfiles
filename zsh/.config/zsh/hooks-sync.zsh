# Shell Hooks for Password Store and Dotfiles Sync
# Provides automatic sync reminders and hooks

# Track when we last checked sync status
SYNC_CHECK_FILE="$HOME/.cache/last-sync-check"
SYNC_REMINDER_INTERVAL=14400  # 4 hours in seconds

# Function to check if sync is needed
check_sync_status() {
    local now=$(date +%s)
    local last_check=0

    if [[ -f "$SYNC_CHECK_FILE" ]]; then
        last_check=$(cat "$SYNC_CHECK_FILE")
    fi

    local elapsed=$((now - last_check))

    if [[ $elapsed -gt $SYNC_REMINDER_INTERVAL ]]; then
        # Check if repositories have uncommitted or unpushed changes
        local needs_sync=false

        # Check password-store
        if [[ -d "$HOME/.password-store/.git" ]]; then
            cd "$HOME/.password-store" 2>/dev/null
            if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
                needs_sync=true
            fi
            local ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo "0")
            if [[ "$ahead" -gt 0 ]]; then
                needs_sync=true
            fi
        fi

        # Check dotfiles
        if [[ -d "$HOME/.dotfiles/.git" ]]; then
            cd "$HOME/.dotfiles" 2>/dev/null
            if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
                needs_sync=true
            fi
            local ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo "0")
            if [[ "$ahead" -gt 0 ]]; then
                needs_sync=true
            fi
        fi

        if [[ "$needs_sync" == true ]]; then
            echo ""
            echo "\033[1;33m⚠ Sync Reminder:\033[0m You have uncommitted or unpushed changes in your repositories."
            echo "   Run: \033[1;32msync\033[0m or \033[1;32msync-status\033[0m to check status"
            echo ""
        fi

        # Update last check time
        echo "$now" > "$SYNC_CHECK_FILE"
    fi
}

# Optional: Run check on each prompt (can be disabled if too frequent)
# Uncomment the following line to enable
# precmd_functions+=(check_sync_status)

# Alternative: Check only on new shell start
# check_sync_status

# Provide a manual check command
alias sync-remind='check_sync_status'

# Auto-sync on shell exit (optional - disabled by default)
# To enable, uncomment the following function
# zshexit() {
#     echo "Running auto-sync before shell exit..."
#     dotfiles-sync --pass-only
# }
