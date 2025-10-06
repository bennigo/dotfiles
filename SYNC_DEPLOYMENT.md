# Sync System Deployment Guide

## Current Situation

**Scripts Location**: `~/.dotfiles/local_bin/.local/bin/`
- ✅ `dotfiles-sync` (16k - enhanced with password-store support)
- ✅ `setup-sync` (2.3k - basic setup)
- ✅ `setup-sync-complete` (8.0k - complete interactive setup)
- ✅ `deploy-sync-scripts` (new - handles deployment)

**Current Deployment Status** (as of now):
- ❌ Scripts NOT yet in `~/.local/bin/` (need to run stow)
- ⚠️  Old `dotfiles-sync` (9.0k) still there from Ansible

## Quick Deployment (Choose One)

### Option 1: Automated (Recommended)

```bash
# Run the complete setup (handles everything)
cd ~/.dotfiles
./local_bin/.local/bin/setup-sync-complete
```

This will:
1. Deploy scripts using stow --adopt (replaces old version)
2. Set up aliases
3. Optionally add Waybar module
4. Optionally enable auto-sync
5. Test everything

### Option 2: Manual Deployment Only

```bash
# Just deploy the scripts without full setup
cd ~/.dotfiles
stow --adopt local_bin

# Verify
ls -la ~/.local/bin/dotfiles-sync
# Should show: symlink → ~/.dotfiles/local_bin/.local/bin/dotfiles-sync

# Test
dotfiles-sync --status
```

### Option 3: Safe Deployment

```bash
# Use the dedicated deployment script
cd ~/.dotfiles
./local_bin/.local/bin/deploy-sync-scripts
```

Shows size comparison and asks for confirmation before replacing.

## Why --adopt?

The `--adopt` flag tells stow: "If a regular file exists, replace it with my symlink"

**What happens**:
```
Before:
~/.local/bin/dotfiles-sync (9.0k regular file from Ansible)

After stow --adopt:
~/.local/bin/dotfiles-sync → ~/.dotfiles/local_bin/.local/bin/dotfiles-sync (16k symlink)
```

**Safe**: The old file content is preserved in the dotfiles repo if needed.

## Verification

After deployment, verify everything works:

```bash
# Check they're symlinks
ls -la ~/.local/bin/dotfiles-sync
ls -la ~/.local/bin/setup-sync*

# Test commands
dotfiles-sync --help
dotfiles-sync --status

# Check size (should be 16k, not 9k)
du -h ~/.local/bin/dotfiles-sync
```

## Troubleshooting

### "Command not found"

Scripts not deployed yet:

```bash
cd ~/.dotfiles
stow --adopt local_bin
```

### "Permission denied"

Scripts not executable:

```bash
chmod +x ~/.dotfiles/local_bin/.local/bin/*
cd ~/.dotfiles
stow --restow local_bin
```

### Old version still running

Cache issue, reload shell:

```bash
hash -r           # Clear bash hash
exec zsh          # Or restart shell
```

### Stow conflicts

If stow complains:

```bash
# Use adopt to replace existing files
cd ~/.dotfiles
stow --adopt local_bin

# Or remove old files first
rm ~/.local/bin/dotfiles-sync
stow local_bin
```

## What Gets Deployed

When you run `stow local_bin`:

```
~/.dotfiles/local_bin/.local/bin/
├── dotfiles-sync (16k)          → ~/.local/bin/dotfiles-sync
├── setup-sync (2.3k)            → ~/.local/bin/setup-sync
├── setup-sync-complete (8.0k)   → ~/.local/bin/setup-sync-complete
├── deploy-sync-scripts          → ~/.local/bin/deploy-sync-scripts
├── getnf                        → ~/.local/bin/getnf
├── run_nvim_obsidian.sh         → ~/.local/bin/run_nvim_obsidian.sh
├── run_screenshot.sh            → ~/.local/bin/run_screenshot.sh
├── run_swappy.sh                → ~/.local/bin/run_swappy.sh
├── sendsshKey.sh                → ~/.local/bin/sendsshKey.sh
└── sway-screenshot              → ~/.local/bin/sway-screenshot
```

All as symlinks pointing back to the dotfiles repo.

## Version Comparison

**Old (Ansible)**:
- Size: 9.0k
- Syncs: dotfiles + claude-private
- No password-store support
- No status command
- Deployed as regular file

**New (Stow)**:
- Size: 16k
- Syncs: dotfiles + claude-private + **password-store**
- Status command with visual indicators
- Pull-before-push logic
- Selective sync options (--pass-only, etc.)
- Deployed as symlink (edit source = instant update)

## After Deployment

Once deployed, you can:

1. **Use immediately**:
   ```bash
   dotfiles-sync --status
   dotfiles-sync
   ```

2. **Complete setup** (adds aliases, Waybar, etc.):
   ```bash
   setup-sync-complete
   ```

3. **Or manual setup**:
   ```bash
   # Add aliases
   echo "source ~/.config/zsh/aliases-sync.zsh" >> ~/.zshrc
   exec zsh

   # Now use convenient aliases
   sync-status
   sync
   ```

## Related Documentation

- **Complete Guide**: `SYNC_WORKFLOW.md`
- **Quick Reference**: `SYNC_QUICK_REFERENCE.md`
- **Waybar Setup**: `waybar/.config/waybar/SETUP_GIT_SYNC.md`
