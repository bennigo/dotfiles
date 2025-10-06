# Password Store & Dotfiles Sync - Quick Reference

## Essential Commands

```bash
sync                # Sync all: password-store + dotfiles + claude
sync-status         # Check status of all repos
sync-pass           # Sync password-store only
```

## After Making Changes

```bash
# After editing passwords
pass edit database/my_credential
sync-pass           # Quick sync

# After config changes
nvim ~/.config/sway/config
sync                # Full sync
```

## Status Indicators

Visual status in Waybar or terminal:
- `✓` Synced with remote
- `↑` Need to push commits
- `↓` Need to pull commits
- `⚠` Uncommitted changes
- `✗` Error

## Setup (One-Time)

```bash
# Deploy everything
cd ~/.dotfiles
stow local_bin zsh waybar systemd

# Quick setup
setup-sync

# Reload shell
exec zsh
```

## Enable Auto-Sync (Optional)

```bash
# Auto-sync every 4 hours
systemctl --user enable --now password-store-sync.timer

# Check it's running
systemctl --user list-timers | grep password-store
```

## Troubleshooting

```bash
# Manual check
cd ~/.password-store && git status
cd ~/.dotfiles && git status

# Force pull
cd ~/.password-store && git pull --rebase

# Force push
cd ~/.password-store && git push
```

## Full Documentation

- Complete guide: `~/.dotfiles/SYNC_WORKFLOW.md`
- GPG/Pass help: `~/.dotfiles/system/gpg-pass-tutorial.md`
