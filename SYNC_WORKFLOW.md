# Automated Sync Workflow for Dotfiles and Password Store

Comprehensive system to keep dotfiles, claude-private, and password-store synchronized across machines with minimal manual intervention.

## Overview

This system prevents you from forgetting to sync your password-store by providing:
1. **Unified sync command** that handles all repositories
2. **Visual status indicators** in your status bar (Waybar)
3. **Automatic periodic syncing** via systemd timers
4. **Shell reminders** for uncommitted changes
5. **Convenient aliases** for quick operations

## Components

### 1. Enhanced Sync Script

**Location**: `~/.local/bin/dotfiles-sync`

**Features**:
- Syncs all three repositories: dotfiles, claude-private, password-store
- Intelligent commit messages based on file changes
- Pull-before-push to avoid conflicts
- Status checking without syncing

**Usage**:
```bash
# Sync everything
dotfiles-sync

# Sync only password-store
dotfiles-sync --pass-only

# Check status without syncing
dotfiles-sync --status

# Preview what would be done
dotfiles-sync --dry-run
```

### 2. Convenient Aliases

**Location**: `~/.config/zsh/aliases-sync.zsh`

**Quick Commands**:
```bash
sync            # Sync all repositories
sync-pass       # Sync only password-store
sync-status     # Show status of all repos
sync-dry        # Preview sync without executing
qsync           # Quick sync (same as 'sync')

# Direct password-store operations
pass-sync       # Pull and push password-store
pass-status     # Git status in password-store
pass-log        # Recent commits in password-store
```

### 3. Visual Status in Waybar (Optional)

**Location**: `~/.config/waybar/scripts/git-sync-status`

Shows repository status in your status bar:
- `✓` - Synced with remote
- `↑` - Commits ahead (need to push)
- `↓` - Commits behind (need to pull)
- `⚠` - Uncommitted changes
- `✗` - Error or not a git repo

**Status Format**: `P:✓ C:✓ D:⚠`
- P = Password Store
- C = Claude Private
- D = Dotfiles

**Integration**:
Add to your Waybar config (`~/.config/waybar/config`):
```json
{
    "modules-right": [..., "custom/git-sync"],
    ...
    "custom/git-sync": {
        "exec": "~/.config/waybar/scripts/git-sync-status",
        "return-type": "json",
        "interval": 60,
        "on-click": "~/.local/bin/dotfiles-sync",
        "tooltip": true,
        "format": " {}"
    }
}
```

### 4. Automatic Periodic Sync (Optional)

**Location**: `~/.config/systemd/user/password-store-sync.{service,timer}`

**Schedule**:
- Every 4 hours while system is running
- Daily at 9am, 1pm, 5pm, 9pm
- 10 minutes after boot

**Enable**:
```bash
# Deploy systemd files (via stow)
stow systemd

# Enable and start the timer
systemctl --user enable password-store-sync.timer
systemctl --user start password-store-sync.timer

# Check status
systemctl --user status password-store-sync.timer
systemctl --user list-timers
```

**Disable** (if you prefer manual syncing):
```bash
systemctl --user stop password-store-sync.timer
systemctl --user disable password-store-sync.timer
```

### 5. Shell Reminders (Optional)

**Location**: `~/.config/zsh/hooks-sync.zsh`

Provides periodic reminders (every 4 hours) if you have uncommitted or unpushed changes.

**Enable**:
Edit `hooks-sync.zsh` and uncomment one of:
```bash
# Option 1: Check on every prompt (might be too frequent)
precmd_functions+=(check_sync_status)

# Option 2: Check only on new shell start (recommended)
check_sync_status
```

**Manual check**:
```bash
sync-remind    # Manually trigger reminder check
```

## Recommended Workflow

### Daily Usage

**Option A: Manual Sync (When You Remember)**
```bash
# Quick status check
sync-status

# Sync everything
sync
```

**Option B: Automatic Sync (Set and Forget)**
```bash
# Enable systemd timer once
systemctl --user enable --now password-store-sync.timer

# That's it! System syncs automatically
# Use visual indicator in Waybar to monitor status
```

**Option C: Hybrid (Best of Both)**
```bash
# Enable timer for periodic backup
systemctl --user enable --now password-store-sync.timer

# Also use shell aliases when you make changes
sync-pass    # After adding/editing passwords
sync         # After making any configuration changes
```

### After Making Changes

**Password Store**:
```bash
# Add or edit passwords
pass edit database/new_credential

# Quick sync
sync-pass
# OR use the full sync
sync
```

**Dotfiles**:
```bash
# Edit configurations
nvim ~/.config/sway/config

# Sync everything
sync
```

**Claude Private**:
```bash
# Claude Code automatically updates files
# Just run sync periodically
sync
```

## Setup Instructions

### Initial Setup

1. **Deploy the sync script**:
   ```bash
   cd ~/.dotfiles
   stow local_bin zsh waybar systemd
   ```

2. **Reload shell** (to load aliases):
   ```bash
   exec zsh
   ```

3. **Test the sync system**:
   ```bash
   # Check current status
   sync-status

   # Preview what would be synced
   sync-dry

   # Perform actual sync
   sync
   ```

4. **(Optional) Enable automatic sync**:
   ```bash
   systemctl --user enable --now password-store-sync.timer
   ```

5. **(Optional) Add Waybar module**:
   - Add `git-sync` module to Waybar config
   - Reload Waybar: `killall waybar; waybar &`

### Testing

```bash
# Test each component individually
dotfiles-sync --help
dotfiles-sync --status
dotfiles-sync --dry-run

# Test password-store specific sync
sync-pass

# Test status script (for Waybar)
~/.config/waybar/scripts/git-sync-status

# Test systemd service
systemctl --user start password-store-sync.service
journalctl --user -u password-store-sync.service -f
```

## Security Considerations

### Safe to Sync
- ✅ Encrypted password files (`.gpg`)
- ✅ Configuration files without secrets
- ✅ GPG-encrypted claude private data

### Never Synced
- ❌ GPG private keys (kept offline)
- ❌ SSH private keys (separate backup)
- ❌ Decrypted passwords (only encrypted files)

### What Gets Committed

**Password Store**:
- Only `.gpg` encrypted files
- Structural changes (folders, organization)
- `.gpg-id` file (public information)

**Dotfiles**:
- Configuration files
- Scripts and automation
- Claude submodule reference (not contents)

**Claude Private**:
- Handled separately in encrypted submodule
- Requires git-crypt unlock to access

## Troubleshooting

### Sync Fails

```bash
# Check git status manually
cd ~/.password-store && git status
cd ~/.dotfiles && git status

# Pull latest changes
cd ~/.password-store && git pull --rebase
cd ~/.dotfiles && git pull --rebase

# Then try sync again
sync
```

### Conflicts

```bash
# For password-store conflicts (rare)
cd ~/.password-store
git status
# Resolve conflicts manually
git add .
git rebase --continue
git push
```

### Timer Not Running

```bash
# Check timer status
systemctl --user status password-store-sync.timer

# View recent runs
systemctl --user list-timers

# Check service logs
journalctl --user -u password-store-sync.service -n 20
```

### Status Indicator Not Showing

```bash
# Test script manually
~/.config/waybar/scripts/git-sync-status

# Check Waybar config
cat ~/.config/waybar/config | grep -A 10 "custom/git-sync"

# Reload Waybar
killall waybar; waybar &
```

## Customization

### Change Sync Frequency

Edit `~/.config/systemd/user/password-store-sync.timer`:
```ini
# Current: every 4 hours
OnUnitActiveSec=4h

# Change to: every 2 hours
OnUnitActiveSec=2h

# Change to: every 12 hours
OnUnitActiveSec=12h
```

Then reload:
```bash
systemctl --user daemon-reload
systemctl --user restart password-store-sync.timer
```

### Disable Automatic Sync

```bash
# Stop and disable timer
systemctl --user stop password-store-sync.timer
systemctl --user disable password-store-sync.timer

# Continue using manual sync
sync
```

### Add Pre/Post Sync Hooks

Edit `~/.local/bin/dotfiles-sync` and add custom functions:
```bash
# Add before sync_password_store() function
pre_sync_hook() {
    # Your custom code here
    echo "Running pre-sync hook..."
}

post_sync_hook() {
    # Your custom code here
    echo "Running post-sync hook..."
}

# Call in main()
main() {
    pre_sync_hook
    # ... existing sync code ...
    post_sync_hook
}
```

## Best Practices

1. **Sync Early, Sync Often**
   - Run `sync` after making credential changes
   - Use `sync-status` to check regularly

2. **Use Descriptive Commits** (automatic)
   - Script generates intelligent commit messages
   - Review with `pass-log` or `git log`

3. **Monitor Status**
   - Keep Waybar indicator visible
   - Check `sync-status` before major changes

4. **Backup Critical Data**
   - GPG private key (offline backup)
   - Recovery codes for 2FA
   - Emergency access procedures

5. **Test Regularly**
   - Periodically test restore on clean system
   - Verify GPG key backups work
   - Practice recovery procedures

## Quick Reference Card

```bash
# Primary Commands
sync                    # Sync all repositories
sync-status             # Check sync status
sync-pass               # Sync password-store only

# Status Checks
pass-status             # Password store git status
pass-log                # Recent password store commits

# Advanced
sync-dry                # Preview without executing
dotfiles-sync  # Full command (same as 'sync')

# Systemd Timer
systemctl --user start password-store-sync.timer   # Enable auto-sync
systemctl --user stop password-store-sync.timer    # Disable auto-sync
systemctl --user status password-store-sync.timer  # Check status
```

## Related Documentation

- **Password Store**: `system/gpg-pass-tutorial.md`
- **Database Setup**: `ansible/DATABASE_SETUP.md`
- **Main Dotfiles**: `CLAUDE.md`
- **System Recovery**: `system/emergency-recovery.md`

---

**Created**: 2025-10-06
**Purpose**: Automated synchronization for dotfiles and password-store
**Maintainer**: Automated via dotfiles-sync script
