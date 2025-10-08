# Sway Wayland Compositor Configuration

This directory contains the complete Sway configuration with power-aware behavior and Nvidia GPU support.

## Overview

**Compositor**: Sway (i3-compatible Wayland compositor)
**GPU**: Nvidia RTX 2000 Ada Generation (AD107GLM)
**Driver**: Nvidia 575 (waiting for 580 in Ubuntu 25.04 repos)
**System**: Ubuntu 25.04, Kernel 6.14.0-33-generic

## Configuration Structure

```
sway/
├── .config/sway/
│   ├── config                    # Main Sway configuration
│   ├── config.d/                 # Modular config includes
│   │   └── bgo-keyboard.conf     # Keyboard-specific settings
│   ├── scripts/                  # Custom automation scripts
│   │   ├── lid-handler.sh        # Power-aware lid event handler
│   │   ├── swayidle-power-aware.sh  # Power-aware idle management
│   │   └── sway-shortcuts.sh     # Shortcut overlay menu
│   └── wallpapers/              # Background images
```

## Power Management Architecture

### Design Philosophy

The power management system uses a **three-layer approach**:

1. **systemd-logind**: Configured to **ignore** all lid events (delegates to Sway)
2. **Sway lid bindings**: Call custom scripts that check AC/battery status
3. **swayidle**: Manages idle timeouts with power-aware suspend behavior

**`★ Insight ─────────────────────────────────────`**
This architecture separates **event detection** (Sway bindswitch) from **policy decisions** (shell scripts checking power status). This allows runtime adaptation without reloading Sway configuration, and provides detailed logging for debugging.
**`─────────────────────────────────────────────────`**

### Power-Aware Behavior

#### Lid Switch (bindswitch)

**On AC Power** (plugged in):
- Close lid → Screen off only (system stays running)
- Use case: Downloads, long-running tasks, docked workflow

**On Battery**:
- Close lid → Lock screen + Full system suspend
- Use case: Maximum power savings when mobile

**Open lid** (both modes):
- Power on display + Restore brightness

#### Idle Timeouts (swayidle)

**Timeline** (both AC and battery):
- **60s**: Dim screen to 10% (save brightness state)
- **300s** (5min): Lock screen with wallpaper
- **900s** (15min): Power off display
- **1800s** (30min): **Conditional suspend** (battery only)

**On AC Power**:
- System stays awake even after 30min idle
- Prevents interrupting background tasks

**On Battery**:
- Full suspend after 30min idle
- Aggressive power saving

### Nvidia-Specific Configuration

#### Current Setup (Driver 575)

**Minimal Configuration Philosophy**:
- Only enable DRM kernel modesetting
- Avoid aggressive workarounds that break suspend/resume
- Keep it simple - modern drivers should "just work"

**Active Settings**:
```bash
# /etc/modprobe.d/nvidia-drm.conf
options nvidia_drm modeset=1
```

**NOT Using** (intentionally disabled):
```bash
# DON'T enable these - they can break suspend/resume
# NVreg_PreserveVideoMemoryAllocations=1  # Breaks hibernation for some
# WLR_DRM_NO_* workarounds                 # Old hacks, not needed
```

#### Nvidia Driver History & Issues

**Driver 575 Status** (Current):
- Known suspend/resume bugs affecting some systems
- Symptoms: `nvidia PM failed to suspend async: error -5`
- Workaround: Resume is working on this fresh installation
- Don't mess with working config!

**Driver 580 Status** (Future):
- Released with improved Wayland support
- ❌ Not available in Ubuntu 25.04 repositories yet
- Expected: Ubuntu 25.10 or backport
- When available: Should improve suspend/resume reliability

**Historical Context**:
- Previous config had aggressive WLR_* environment variables (lines 72-77, commented out)
- Those were old workarounds for early Wayland+Nvidia compatibility
- Modern drivers don't need them
- Lid handling was disabled during Nvidia 580 testing (Sept 2025)
- Now re-enabled with power-aware scripts

#### systemd-logind Configuration

**Required for Sway lid handling**:

File: `/etc/systemd/logind.conf.d/90-sway-lid.conf`
```ini
[Login]
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
LidSwitchIgnoreInhibited=no
```

**Installation**:
```bash
sudo cp ~/.dotfiles/system/etc/systemd/logind.conf.d/90-sway-lid.conf /etc/systemd/logind.conf.d/
sudo systemctl restart systemd-logind  # Warning: Kills graphical session!
```

**Why This Matters**:
- By default, systemd handles lid events (usually suspends)
- This conflicts with Sway's bindswitch directives
- Setting to `ignore` allows Sway to control lid behavior
- Enables power-aware logic in our custom scripts

### Script Details

#### lid-handler.sh

**Purpose**: Handle lid open/close events with AC/battery awareness

**AC Detection Methods** (in priority order):
1. `acpi -a` command (most reliable)
2. `/sys/class/power_supply/AC/online` file
3. Fallback to other AC adapter paths
4. Default to battery mode (safer)

**Logging**: `$XDG_RUNTIME_DIR/sway-lid-handler.log`

**Key Features**:
- Saves/restores brightness state
- Locks before suspend on battery
- Emergency recovery: $mod+Ctrl+b (force display on + 50% brightness)

#### swayidle-power-aware.sh

**Purpose**: Launch swayidle with conditional suspend behavior

**How It Works**:
1. Script starts swayidle with standard timeouts
2. Final timeout calls script with `--suspend-check` flag
3. Script checks AC status before suspending
4. Suspend only executes on battery

**Logging**: `$XDG_RUNTIME_DIR/swayidle-power-aware.log`

**Customization**:
Edit timeout values at top of script:
```bash
TIMEOUT_DIM=60           # Dim screen
TIMEOUT_LOCK=300         # Lock screen
TIMEOUT_SCREEN_OFF=900   # Power off display
TIMEOUT_SUSPEND=1800     # Conditional suspend
```

## Troubleshooting

### Lid Events Not Working

**Check systemd-logind configuration**:
```bash
# View current settings
loginctl show-session $(loginctl | grep $(whoami) | awk '{print $1}') | grep Handle

# Should show:
# HandleLidSwitch=ignore
# HandleLidSwitchExternalPower=ignore
```

**Check script logs**:
```bash
tail -f $XDG_RUNTIME_DIR/sway-lid-handler.log
tail -f $XDG_RUNTIME_DIR/swayidle-power-aware.log
```

**Test AC detection**:
```bash
~/.config/sway/scripts/lid-handler.sh close  # Dry run
```

### Black Screen After Resume

**Emergency recovery**:
- Press `$mod+Ctrl+b` to force display on + 50% brightness
- Or: `$mod+Shift+z` to restore display + saved brightness

**Check Nvidia driver state**:
```bash
# Nvidia modules loaded?
lsmod | grep nvidia

# Driver communicating?
nvidia-smi

# If failed, reload modules:
sudo modprobe -r nvidia_drm nvidia_modeset nvidia
sudo modprobe nvidia nvidia_modeset nvidia_drm
```

### Suspend Not Working

**Check power detection**:
```bash
# Method 1
acpi -a

# Method 2
cat /sys/class/power_supply/AC/online
```

**Force suspend test**:
```bash
systemctl suspend
```

**Check journal for errors**:
```bash
journalctl -b -u systemd-logind | grep -i lid
journalctl -b -k | grep -i nvidia
```

## Keyboard Shortcuts

### Power Management

| Shortcut | Action | Description |
|----------|--------|-------------|
| `$mod+x` | Lock screen | Immediate lock with wallpaper |
| `$mod+Shift+x` | Suspend | Manual system suspend |
| `$mod+Ctrl+b` | Emergency display on | Force panel on + 50% brightness |
| `$mod+Shift+z` | Restore display | Power on + restore brightness |

### Other Key Bindings

See `config` file for complete list, or press `$mod+/` for interactive shortcut overlay.

## References

### Related Documentation

- **Main dotfiles**: `~/.dotfiles/CLAUDE.md`
- **System setup**: `~/.dotfiles/system/CLAUDE.md`
- **Nvidia config**: `~/.dotfiles/system/etc/modprobe.d/nvidia-drm.conf`
- **logind override**: `~/.dotfiles/system/etc/systemd/logind.conf.d/90-sway-lid.conf`

### Obsidian Notes

- **Nvidia 580 analysis**: `~/notes/bgovault/2.Areas/Linux/1772927204-nvidia-580-driver-analysis.md`
- **Nvidia driver config**: `~/notes/bgovault/2.Areas/Linux/1755609432-nvidia-driver-config.md`
- **Sway display bindings**: `~/notes/bgovault/2.Areas/Linux/1755776355-sway-bindsym-display.md`

### External Resources

- [Sway Wiki - Systemd Integration](https://github.com/swaywm/sway/wiki/Systemd-integration)
- [Nvidia Suspend Fix](https://gist.github.com/bmcbm/375f14eaa17f88756b4bdbbebbcfd029)
- [swayidle GitHub](https://github.com/swaywm/swayidle)

## Development Notes

### Making Changes

**Edit source files in dotfiles repo**, not deployed locations:
```bash
# Edit config
vim ~/.dotfiles/sway/.config/sway/config

# Deploy with stow
cd ~/.dotfiles
stow sway

# Test without applying
sway -C ~/.config/sway/config

# Reload live session
swaymsg reload
```

### Adding New Scripts

```bash
# Create script
vim ~/.dotfiles/sway/.config/sway/scripts/new-script.sh

# Make executable
chmod +x ~/.dotfiles/sway/.config/sway/scripts/new-script.sh

# Deploy
stow sway

# Use in config
bindsym $mod+key exec ~/.config/sway/scripts/new-script.sh
```

### Testing Power-Aware Behavior

**Test AC detection**:
```bash
# Should detect current power state
~/.config/sway/scripts/lid-handler.sh close
# Check log for "on AC power" or "on battery"
tail $XDG_RUNTIME_DIR/sway-lid-handler.log
```

**Test lid handling**:
1. On AC: Close lid → Screen should turn off, system stays running
2. On battery: Close lid → Screen off + suspend should trigger
3. Open lid: Display should restore

**Monitor swayidle**:
```bash
# Watch idle state changes
tail -f $XDG_RUNTIME_DIR/swayidle-power-aware.log
```

## Known Limitations

1. **Nvidia 575 driver**: Occasional suspend/resume glitches
   - Workaround: Emergency display restore shortcuts
   - Fix: Wait for driver 580 in Ubuntu repos

2. **Docked detection**: Wayland can't distinguish DPMS-off from disabled outputs
   - Impact: HandleLidSwitchDocked may not work as expected
   - Solution: Use AC power detection instead

3. **swayidle restart**: Script kills existing swayidle on launch
   - Impact: Brief gap in idle monitoring during config reload
   - Acceptable: Only happens on `exec_always` triggers

## Future Improvements

- [ ] Add configurable timeouts via environment variables or config file
- [ ] Implement battery percentage thresholds (aggressive suspend at <20%)
- [ ] Add notification before auto-suspend (with cancel option)
- [ ] Test Nvidia 580 driver when available in Ubuntu 25.04
- [ ] Consider elogind vs systemd-logind for non-systemd setups

---

**Last Updated**: 2025-10-08
**Maintainer**: BGO
**Status**: Production - tested on fresh Ubuntu 25.04 installation
