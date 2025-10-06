# Setting Up Git Sync Status in Waybar

## Quick Setup

Run the automated setup script:

```bash
~/.config/waybar/scripts/setup-git-sync-module
```

This will automatically:
1. Add the git-sync module to your Waybar config
2. Add CSS styling for the module
3. Reload Waybar

## Manual Setup (Alternative)

If you prefer to do it manually or the script fails:

### Step 1: Add Module to Waybar Config

Edit `~/.config/waybar/config.jsonc`:

**Add to `modules-right` array** (suggested position: after `custom/clipboard` or before `cpu`):

```jsonc
"modules-right": [
    "custom/weather",
    "custom/wlsunset",
    "custom/playerctl",
    "custom/help",
    "idle_inhibitor",
    "custom/dnd",
    "sway/language",
    "custom/clipboard",
    "custom/git-sync",        // ← ADD THIS LINE
    "cpu",
    "memory",
    // ... rest of modules
],
```

**Add module configuration** at the bottom of the file (before the final `}`):

```jsonc
    "custom/git-sync": {
        "exec": "~/.config/waybar/scripts/git-sync-status",
        "return-type": "json",
        "interval": 60,
        "on-click": "kitty -e ~/.local/bin/dotfiles-sync",
        "on-click-right": "kitty -e ~/.local/bin/dotfiles-sync --status",
        "tooltip": true,
        "format": " {}"
    }
```

### Step 2: Add CSS Styling

Edit `~/.config/waybar/style.css` and add at the end:

```css
/* Git Sync Status Module */
#custom-git-sync {
    padding: 0 10px;
    margin: 0 4px;
    border-radius: 4px;
}

#custom-git-sync.synced {
    color: #a6da95;  /* Green - all synced */
}

#custom-git-sync.pending {
    color: #eed49f;  /* Yellow - needs sync */
    animation: pulse 2s ease-in-out infinite;
}

#custom-git-sync.error {
    color: #ed8796;  /* Red - error */
}

@keyframes pulse {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.6; }
}
```

### Step 3: Reload Waybar

```bash
killall waybar
waybar &
```

Or if using systemd:

```bash
systemctl --user restart waybar
```

## Module Behavior

### Visual Indicators

The module shows status for three repositories:

**Format**: `P:✓ C:✓ D:↑`

- **P** = Password Store
- **C** = Claude Private
- **D** = Dotfiles

**Status symbols**:
- `✓` = Synced with remote (green)
- `↑` = Commits ahead (need to push) (yellow, pulsing)
- `↓` = Commits behind (need to pull) (yellow, pulsing)
- `⚠` = Uncommitted changes (yellow, pulsing)
- `✗` = Error (red)

### Interactions

- **Left Click**: Opens terminal and runs `dotfiles-sync` (syncs all repos)
- **Right Click**: Opens terminal and shows sync status
- **Hover**: Shows tooltip with detailed status

### Update Frequency

- Checks status every 60 seconds
- Updates immediately after clicking

## Customization

### Change Update Interval

In `config.jsonc`, change the `interval` value (in seconds):

```jsonc
"interval": 60,     // Current: every minute
"interval": 300,    // Change to: every 5 minutes
"interval": 30,     // Change to: every 30 seconds
```

### Change Terminal Emulator

If you don't use `kitty`, change the terminal in `config.jsonc`:

```jsonc
// For foot terminal
"on-click": "foot -e ~/.local/bin/dotfiles-sync",

// For alacritty
"on-click": "alacritty -e ~/.local/bin/dotfiles-sync",

// For gnome-terminal
"on-click": "gnome-terminal -- ~/.local/bin/dotfiles-sync",
```

### Change Icon

In `config.jsonc`, change the format line:

```jsonc
"format": " {}",    // Git icon
"format": " {}",    // Sync icon
"format": " {}",    // Cloud icon
"format": "⚡ {}",   // Lightning icon
"format": "{}",      // No icon, just status
```

### Position in Bar

Move `"custom/git-sync"` in the `modules-right` array to your preferred position:

```jsonc
// At the beginning
"modules-right": [
    "custom/git-sync",  // ← First
    "custom/weather",
    // ...
],

// At the end (before tray)
"modules-right": [
    // ...
    "clock",
    "custom/git-sync",  // ← Before tray
    "tray"
],
```

## Troubleshooting

### Module Not Appearing

1. **Check script is executable**:
   ```bash
   chmod +x ~/.config/waybar/scripts/git-sync-status
   ```

2. **Test script manually**:
   ```bash
   ~/.config/waybar/scripts/git-sync-status
   ```
   Should output JSON like: `{"text":"P:✓ C:✓ D:✓","tooltip":"...","class":"synced"}`

3. **Check Waybar logs**:
   ```bash
   # If running manually
   killall waybar
   waybar 2>&1 | grep git-sync

   # If running via systemd
   journalctl --user -u waybar -f
   ```

### Module Shows Error (✗)

The script checks three repositories. Verify each exists:

```bash
# Check all repos
ls -la ~/.dotfiles/.git
ls -la ~/.dotfiles/claude-private/.git
ls -la ~/.password-store/.git
```

### Click Actions Not Working

1. **Test commands directly**:
   ```bash
   ~/.local/bin/dotfiles-sync --status
   ```

2. **Check terminal emulator**:
   ```bash
   which kitty
   # If not installed, change to your terminal (foot, alacritty, etc.)
   ```

### CSS Styling Not Applied

1. **Check CSS syntax** - ensure no missing braces or semicolons
2. **Reload Waybar completely**:
   ```bash
   killall -9 waybar
   sleep 1
   waybar &
   ```

## Testing

### Test the Status Script

```bash
# Run manually
~/.config/waybar/scripts/git-sync-status

# Expected output (JSON format)
{
    "text": "P:✓ C:✓ D:⚠",
    "tooltip": "Password Store: ✓ | Claude: ✓ | Dotfiles: ⚠\n\nClick to sync all repositories",
    "class": "pending"
}
```

### Test Click Actions

```bash
# Test sync command
~/.local/bin/dotfiles-sync --status

# Test terminal launch
kitty -e ~/.local/bin/dotfiles-sync --status
```

## Related Documentation

- **Main Sync Guide**: `~/.dotfiles/SYNC_WORKFLOW.md`
- **Quick Reference**: `~/.dotfiles/SYNC_QUICK_REFERENCE.md`
- **Waybar Documentation**: https://github.com/Alexays/Waybar/wiki

---

**Note**: After making any changes to Waybar config, remember to reload Waybar for changes to take effect!
