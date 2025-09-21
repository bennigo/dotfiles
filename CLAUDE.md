# CLAUDE.md

This file provides guidance to Claude Code when working with this dotfiles repository.

## Repository Overview

Personal dotfiles repository for Sway-based Linux desktop environment. Uses modular configuration management with GNU Stow for deployment.

## System Environment

### Linux Distribution
- **OS**: Linux (Ubuntu-based or similar)
- **Kernel**: Linux 6.14.0-29-generic
- **Architecture**: x86_64
- **Package Manager**: apt, snap, flatpak support

### Desktop Environment
- **Compositor**: Sway (Wayland-based i3-compatible)
- **Status Bar**: Waybar with custom modules
- **Application Launcher**: Rofi
- **Terminal Emulators**: Kitty (primary), Foot (lightweight), Alacritty (cross-platform)
- **Notification System**: Mako
- **Screenshot Tools**: Grim + Swappy + Slurp
- **File Manager**: Ranger (terminal), Nautilus (GUI)

### Hardware Support
- **Display Server**: Wayland (Sway compositor)
- **GPU**: Nvidia support configured
- **Input**: Keyboard/mouse with custom udev rules

## Architecture

### Directory Structure

```
.dotfiles/
├── sway/          # Sway compositor configuration
├── waybar/        # Status bar with custom modules
├── neovim/        # Editor configuration (LazyVim-based, built from source)
├── neovim_old/    # Previous neovim configuration backup
├── tmux/          # Terminal multiplexer config
├── local_bin/     # Custom executable scripts
├── system/        # System-level configs and installation (see system/CLAUDE.md)
├── ansible/       # System provisioning and automation
├── kitty/         # Terminal emulator configuration
├── foot/          # Lightweight terminal emulator
├── alacritty/     # Cross-platform terminal emulator
├── qutebrowser/   # Keyboard-driven web browser
├── swappy/        # Screenshot annotation tool
├── zsh/           # Shell configuration
├── profile/       # Shell profile settings
├── i3/            # Legacy i3 configuration (excluded from stow)
└── [app]/         # Per-application config directories
```

### Configuration Pattern

Each directory contains complete `.config/[app]` structure for GNU Stow deployment:

```bash
stow sway waybar neovim tmux  # Deploy multiple configs
stow -t ~ sway                # Deploy single config
```

## Key Features

### Smart Shortcut System (`sway/.config/sway/config`)

Structured comment format for dynamic shortcut overlays:

```
## Category // Description // Icon ##
bindsym $mod+key command
```

- Parsed by `sway-shortcuts.sh` script
- Generates searchable, categorized rofi menus

### Custom Scripts

- **`local_bin/`**: System utilities and application launchers
- **`sway/.config/sway/scripts/`**: Sway-specific automation
- **`waybar/.config/waybar/scripts/`**: Status bar modules

### System Automation

- **Ansible**: Comprehensive system provisioning and configuration management
- **Bootstrap system**: Automated setup for fresh installations
- **Credentials management**: Encrypted vault with GPG/pass integration
- **SSH key automation**: Automated extraction and deployment from vault

### Development Integration

- **Neovim**: LazyVim-based setup with custom snippets, built from source with full dependencies
- **Claude Code**: Integrated AI coding assistant with API key management
- **Tmux**: Session management with plugin ecosystem
- **Terminal**: Multiple emulator configs (kitty, foot, alacritty)
- **Shell**: Zsh with custom profile configurations
- **Browser**: Qutebrowser for keyboard-driven web browsing
- **Languages**: Go, Rust, Node.js/FNM, Python/uv, R statistical computing
- **Notes**: Obsidian vault integration with PARA method organization

## Common Operations

### Configuration Management

```bash
# Deploy configurations
cd ~/.dotfiles
stow sway waybar neovim

# Test sway configuration
sway -C ~/.config/sway/config

# Reload sway
swaymsg reload
```

### System Provisioning

```bash
# Run complete Ansible bootstrap (fresh installation)
cd ~/.dotfiles/ansible
ansible-playbook site.yml

# Target specific roles
ansible-playbook site.yml --tags "development"        # Dev tools only
ansible-playbook site.yml --tags "sway,neovim"       # Desktop + editor
ansible-playbook site.yml --tags "dotfiles"          # Stow deployment only
ansible-playbook site.yml --tags "credentials"       # Vault management only
```

### Script Development

```bash
# Make scripts executable
chmod +x ~/.local/bin/new_script.sh
chmod +x ~/.config/sway/scripts/new_script.sh

# Test sway shortcuts overlay
~/.config/sway/scripts/sway-shortcuts.sh
```

### System Services

```bash
# System services
sudo systemctl status udevmon
sudo systemctl restart udevmon

# User services  
systemctl --user status pipewire
systemctl --user restart waybar

# Check Wayland session
echo $WAYLAND_DISPLAY
loginctl show-session $(loginctl | grep $(whoami) | awk '{print $1}')
```

### Hardware Management

```bash
# Test Nvidia configuration
./system/nvidia.test

# Check GPU status
nvidia-smi
swaymsg -t get_outputs

# Input device debugging
udevadm monitor --environment --udev
```

## System Integration

### Wayland Compatibility
- **XWayland**: Legacy X11 application support enabled
- **Screen sharing**: Portal-based sharing for Wayland applications
- **Clipboard**: wl-clipboard for Wayland-native copy/paste

### Performance Optimization
- **Nvidia**: Early KMS for optimal Wayland performance
- **Input latency**: Custom udev rules for gaming/professional input devices
- **Resource management**: Systemd user services for session components
- **Environment variables**: PAM-based XDG configuration for consistent paths

## Cross-References

- **System installation, hardware setup, and credentials**: `system/CLAUDE.md`
- **Global workspace context**: `/home/bgo/CLAUDE.md`
- **Project-specific contexts**: Individual project CLAUDE.md files

## Development Notes

### Adding Configurations

1. Create new directory with `.config/[app]` structure
2. Add application configs inside
3. Update this CLAUDE.md if significant patterns emerge
4. Deploy with `stow [app]`

### Script Dependencies

Common dependencies across custom scripts:

- rofi (menus and launchers)
- jq (JSON processing for sway IPC)
- waybar (status bar integration)

### File Editing Preference

Edit source files in dotfiles repository, not deployed locations in `~/.config/`.

### Stow Configuration

Ansible automatically deploys all stowable directories except:
- `ansible/` (build system)
- `system/` (system configs)
- `i3/` (legacy configuration, unused)
- `sway-remix/` (experimental)
- `.git/` (version control)
- Hidden directories (starting with `.`)

### Recent System Improvements

- **Fresh install automation**: Complete Ansible bootstrap for clean deployments
- **Neovim source build**: Latest features with full dependency management
- **Plugin compatibility**: Updated LazyVim with catppuccin integration fixes
- **Environment consistency**: PAM-based XDG variables for reliable path resolution
- **R integration**: Statistical computing environment with language server support
- **LaTeX support**: Full TeX Live distribution with Icelandic language support
- **Claude Code integration**: AI assistant with secure API key management
- **Vault automation**: Encrypted credential storage with SSH key deployment
- **Obsidian integration**: Personal knowledge management with PARA organization

