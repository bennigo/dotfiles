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
├── neovim/        # Editor configuration (LazyVim-based, built from source) - see neovim/.config/nvim/CLAUDE.md
├── neovim_old/    # Previous neovim configuration backup
├── tmux/          # Terminal multiplexer config
├── local_bin/     # Custom executable scripts
├── system/        # System-level configs and installation (see system/CLAUDE.md)
├── ansible/       # System provisioning and automation (includes PostgreSQL 18 setup)
├── kitty/         # Terminal emulator configuration
├── foot/          # Lightweight terminal emulator
├── alacritty/     # Cross-platform terminal emulator
├── qutebrowser/   # Keyboard-driven web browser
├── swappy/        # Screenshot annotation tool
├── zsh/           # Shell configuration
├── profile/       # Shell profile settings
├── docker/        # Docker Engine configuration, scripts, and compose templates (see docker/CLAUDE.md)
├── claude-code/   # Claude Code CLI and MCP server configurations (see claude-code/README.md)
├── containers/    # Container/Podman configuration (minimal - only registries.conf)
├── ranger/        # File manager (minimal - needs proper configuration)
├── systemd/       # User systemd services (basic - mako-watcher only)
├── neomutt/       # Email client (structure present, needs post-reinstall setup)
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

- **Neovim**: LazyVim-based setup (75+ plugins) with Claude Code, Database UI, Obsidian integration - see `neovim/.config/nvim/CLAUDE.md`
- **PostgreSQL 18**: Production database with secure credential management via `pass` - see `ansible/DATABASE_SETUP.md`
- **Docker Engine 28.4.0**: Container orchestration with Compose v2, utility scripts, templates - see `docker/CLAUDE.md`
- **Claude Code**: Integrated AI coding assistant with MCP server integrations - see `claude-code/README.md`
- **Database UI**: vim-dadbod-ui integration in Neovim for direct database access
- **Tmux**: Session management with plugin ecosystem
- **Terminal**: Multiple emulator configs (kitty, foot, alacritty)
- **Shell**: Zsh with custom profile configurations
- **Browser**: Qutebrowser for keyboard-driven web browsing
- **Languages**: Go, Rust, Node.js/FNM, Python/uv, R statistical computing
- **Containerization**: Docker with VPN-friendly networking, GPS receivers scheduler
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
ansible-playbook bootstrap.yml --extra-vars "profile=work_laptop"

# Target specific profiles
ansible-playbook bootstrap.yml --extra-vars "profile=development"  # Dev tools + database
ansible-playbook bootstrap.yml --extra-vars "profile=desktop"      # Full desktop + database

# Target specific roles
ansible-playbook bootstrap.yml --tags "development"        # Dev tools only
ansible-playbook bootstrap.yml --tags "database"           # PostgreSQL + credential scripts
ansible-playbook bootstrap.yml --tags "dotfiles"           # Stow deployment only
ansible-playbook bootstrap.yml --tags "credentials"        # Vault management only
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

### Database Management (PostgreSQL 18)

```bash
# Setup database credentials from password store
git clone git@github.com:bennigo/bgo-pstore.git ~/.password-store
update-pgpass              # Generates ~/.pgpass from pass credentials

# Database operations
psql bgo                    # Connect to default database
createdb myproject          # Create new database
psql myproject             # Connect to specific database

# Neovim database UI (vim-dadbod-ui)
nvim                       # Database connections via db_ui (:DBUI or <leader>D)
                           # Saved queries in ~/.config/nvim/db_ui/

# Update credentials
pass edit database/vedur_password
update-pgpass              # Regenerate .pgpass file

# Database status
sudo systemctl status postgresql
psql --version             # PostgreSQL 18.0
```

**See detailed documentation**: `ansible/DATABASE_SETUP.md`

### Docker Container Management

```bash
# Container operations
docker ps                           # List running containers
docker compose up -d                # Start services in background
docker compose down                 # Stop and remove containers
docker-logs-follow web db           # Follow logs from multiple containers

# Cleanup and maintenance
docker-cleanup                      # Interactive cleanup (custom script)
docker-cleanup --all --force        # Remove all unused images, no confirmation
docker-stats-pretty                 # Colorized container statistics

# Using compose templates
cp ~/.dotfiles/docker/templates/compose-python-dev.yml docker-compose.yml
cp ~/.dotfiles/docker/templates/.env.example .env
# Edit .env and docker-compose.yml, then:
docker compose up -d

# Current running containers
docker ps -f name=gps-receivers    # GPS receivers scheduler
```

**See detailed documentation**: `docker/CLAUDE.md`

### PDF Document Management

```bash
# Sign PDF documents with signature image
sign-pdf input.pdf signature.png output.pdf                    # Sign at bottom-right corner
sign-pdf input.pdf sig.png output.pdf --position 100 100       # Sign at specific position
sign-pdf input.pdf sig.png output.pdf --page -1                # Sign last page
sign-pdf input.pdf sig.png output.pdf --width 200 --height 80  # Custom signature size

# View help and examples
sign-pdf --help
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

- **Neovim plugin ecosystem and configuration**: `neovim/.config/nvim/CLAUDE.md` (75+ plugins, LazyVim-based)
- **Docker Engine configuration and workflows**: `docker/CLAUDE.md` (daemon config, scripts, compose templates)
- **Database setup and credential management**: `ansible/DATABASE_SETUP.md` (PostgreSQL 18)
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

- **PostgreSQL 18 Integration**: Production database with secure credential management via GPG-encrypted `pass` store
  - Full Ansible automation for installation and user setup
  - Neovim Database UI (vim-dadbod-ui) for direct database access
  - Password-less connections via `~/.pgpass` (auto-generated from `pass`)
  - See: `ansible/DATABASE_SETUP.md` for complete documentation
- **Neovim Ecosystem**: 75+ plugins documented in dedicated `neovim/.config/nvim/CLAUDE.md`
  - Built from source (v0.11.4) with full dependency management
  - LazyVim foundation with extensive customization
  - Claude Code, Database UI, Obsidian, R statistical computing integrations
  - Multi-language support: Python, R, LaTeX, Lua, Markdown
- **Obsidian Workflow Tools**: Integrated PDF signing utility (`sign-pdf`)
  - CLI tool for adding signature images to PDF documents
  - Deployed via Ansible with automatic dependency management
  - Python-based with pypdf, Pillow, and ReportLab
- **Fresh install automation**: Complete Ansible bootstrap for clean deployments
- **Environment consistency**: PAM-based XDG variables for reliable path resolution
- **Claude Code integration**: AI assistant with secure API key management
- **Vault automation**: Encrypted credential storage with SSH key deployment
- **Password management**: GPG-encrypted password store with version control (private repo)

### Configuration Gaps (Post-Reinstall TODO)

- **Neomutt**: Structure present, needs configuration after laptop reinstallation
- **Ranger**: Minimal configuration (only rc.conf), needs proper setup
- **Systemd user services**: Basic setup (mako-watcher only), could be expanded

