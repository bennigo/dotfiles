# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository for a Linux system using Sway (Wayland compositor) and related tools. It contains configuration files and custom scripts for a complete desktop environment setup.

## Architecture and Structure

### Directory Organization
- **sway/**: Sway compositor configuration with window management rules, keybindings, and custom scripts
- **waybar/**: Status bar configuration with custom scripts for network, weather, and system controls
- **neovim/**: Neovim editor configuration with Lua-based plugins and custom snippets
- **tmux/**: Terminal multiplexer configuration with plugins and custom scripts
- **system/**: System-level configuration files, installation scripts, and credentials management
- **local_bin/**: Custom executable scripts and utilities
- **profile/**, **zsh/**: Shell environment configuration
- **kitty/**, **foot/**, **alacritty/**: Terminal emulator configurations
- **qutebrowser/**: Web browser configuration

### Key Components

#### Sway Configuration (`sway/.config/sway/config`)
- Main configuration file with extensive keybinding definitions
- Uses structured comment format: `## Category // Description // Icon ##`
- Scratchpad management for floating applications (Obsidian, Cisco client, terminals)
- Custom window rules and workspace assignments
- Integration with screenshot tools, clipboard manager, and media controls

#### Custom Scripts Directory (`sway/.config/sway/scripts/`)
- `sway-shortcuts.sh`: Dynamic shortcut overlay generator that parses sway config comments
- Uses rofi for interactive display of categorized shortcuts with icons

#### System Scripts (`local_bin/`)
- Contains executable scripts for various system functions
- Screenshot utilities, application launchers, and system management tools

#### Installation and Setup (`system/install.txt`)
- Comprehensive installation script with all dependencies
- Package manager commands for system setup
- Development environment configuration (Node.js, Rust, Python, etc.)

### Configuration Management

The repository uses a modular approach where each application has its own directory containing the complete `.config` structure. This allows for easy deployment using tools like GNU Stow.

### Key Features

1. **Smart Shortcut System**: Sway configuration includes structured comments that are parsed by `sway-shortcuts.sh` to generate categorized, searchable shortcut overlays
2. **Scratchpad Integration**: Pre-configured floating windows for quick access to frequently used applications
3. **Screenshot Workflow**: Integrated screenshot system with annotation support via swappy
4. **Development Environment**: Full setup for multiple programming languages and tools
5. **System Integration**: Custom scripts for system management, media control, and desktop functionality

## Common Commands

### System Management
```bash
# Initial system setup (run once)
cd ~/.dotfiles/system/
# Follow install.txt instructions

# Apply configurations using stow (example)
stow sway waybar neovim tmux
```

### Configuration Testing
```bash
# Reload sway configuration
swaymsg reload

# Test sway configuration syntax
sway -C ~/.config/sway/config

# Show current keybindings
~/.config/sway/scripts/sway-shortcuts.sh
```

### Script Development
When modifying custom scripts in `local_bin/` or `sway/scripts/`, ensure they are executable:
```bash
chmod +x ~/.local/bin/script_name.sh
chmod +x ~/.config/sway/scripts/script_name.sh
```

## Development Notes

### Sway Shortcut Comments
When adding new keybindings to the sway config, use the structured comment format for integration with the shortcuts overlay:
```
## Category // Description // Icon ##
bindsym $mod+key command
```

### Script Dependencies
Custom scripts may depend on:
- rofi (application launcher and menus)
- jq (JSON processing for sway IPC)
- waybar (status bar)
- Various command-line utilities (see install.txt for complete list)

### File Modifications
Most configuration changes should be made to the source files in the dotfiles repository, then deployed to their target locations. Avoid editing files directly in `~/.config/` as changes may be overwritten.