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
├── systemd/       # User systemd services (claude-imports, tmux, password-store-sync, mako-watcher, mtp-automount)
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

### User Systemd Services

The `systemd/` package contains 7 user service units deployed with `stow --no-folding` to prevent
stow from tree-folding `~/.config/systemd/` (which would cause `systemctl --user enable` to write
`.wants/` symlinks inside the git repo).

| Unit | Type | Activation | Purpose |
|------|------|-----------|---------|
| `claude-imports.service` | Long-running | `enable --now` | Watches Downloads for vault notes and Claude exports |
| `mako-watcher.path` | Path trigger | `enable --now` | Triggers mako-watcher.service on config file changes |
| `mako-watcher.service` | Triggered | via `.path` | Reloads Mako notification daemon on config change |
| `password-store-sync.timer` | Timer | `enable --now` | Schedules periodic password store and dotfiles sync |
| `password-store-sync.service` | Triggered | via `.timer` | Runs the actual sync (git pull/push) |
| `tmux.service` | Forking | `enable` only | Starts detached tmux session at login |
| `mtp-automount@.service` | Template | on-demand | MTP device automount (activated by udev rules) |

```bash
# Deploy systemd services (uses --no-folding to keep .wants/ out of repo)
cd ~/.dotfiles
stow -R --no-folding systemd

# Check service status
systemctl --user status claude-imports password-store-sync.timer mako-watcher.path tmux

# View all managed unit files
systemctl --user list-unit-files | grep -E '(claude|tmux|mako|password|mtp)'
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

### Wayland Environment in Tmux

After reboot, `tmux-continuum` restores sessions before Sway starts, leaving `WAYLAND_DISPLAY`,
`SWAYSOCK`, and `DISPLAY` empty in restored panes. Two mechanisms fix this:

- **Auto-refresh**: `zsh/exports.zsh` defines `refresh-wayland-env` which pulls current values from
  the tmux session env (populated by `update-environment` on attach). Runs automatically on shell
  startup when `WAYLAND_DISPLAY` is empty inside tmux.
- **Manual bulk refresh**: `prefix + E` (tmux keybinding) sends `refresh-wayland-env` + Enter to
  every pane across all sessions — useful for long-running shells that never re-sourced.

```bash
# Manual refresh in a single pane
refresh-wayland-env

# Bulk refresh all panes (tmux prefix + E)
# Verify
echo $WAYLAND_DISPLAY  # Should show wayland-1
```

### Claude Code Notifications

Claude Code notifications are forwarded to Mako via a hook in `~/.claude/settings.json`.
The `claude-notify` script (`local_bin/`) reads hook JSON on stdin and calls `notify-send`
with urgency based on event type (critical for permission prompts, normal for idle prompts).

This is needed because inside Neovim's terminal buffer, standard terminal notification
mechanisms (OSC sequences, bells) are swallowed — the hook runs as a separate process and
reaches Mako directly via D-Bus.

```bash
# Test the notification hook manually
echo '{"notification_type":"idle_prompt","message":"Test","title":"Claude Code"}' | claude-notify
```

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
- jq (JSON processing for sway IPC, tmux statusline, claude-notify)
- waybar (status bar integration)
- libnotify-bin (notify-send for claude-notify and desktop notifications)

### File Editing Preference

Edit source files in dotfiles repository, not deployed locations in `~/.config/`.

### Stow Configuration

Ansible automatically deploys all stowable directories except:
- `ansible/` (build system)
- `system/` (system configs)
- `i3/` (legacy configuration, unused)
- `sway-remix/` (experimental)
- `systemd/` (deployed separately with `--no-folding`, see below)
- `.git/` (version control)
- Hidden directories (starting with `.`)

The `systemd` package is stowed separately with `stow --no-folding` so that `~/.config/systemd/user/`
is a real directory. This prevents `systemctl --user enable` from creating `.wants/` symlinks inside the
git repo. Ansible also enables and starts the appropriate services after deployment.

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
- **Wayland env refresh for tmux**: Auto-fixes stale `WAYLAND_DISPLAY`/`SWAYSOCK`/`DISPLAY` in
  tmux-continuum restored sessions, with manual `prefix + E` bulk refresh keybinding
- **Claude Code notification hook**: `claude-notify` script forwards Claude Code `Notification`
  hook events to Mako via `notify-send` — works inside Neovim terminal where OSC sequences are swallowed
- **Fresh install automation**: Complete Ansible bootstrap for clean deployments
- **Environment consistency**: PAM-based XDG variables for reliable path resolution
- **Claude Code integration**: AI assistant with secure API key management
- **Vault automation**: Encrypted credential storage with SSH key deployment
- **Password management**: GPG-encrypted password store with version control (private repo)

### Configuration Gaps (Post-Reinstall TODO)

- **Neomutt**: Structure present, needs configuration after laptop reinstallation
  - [ ] **mbsync setup complete**: `.mbsyncrc` created for Gmail
  - [ ] **TODO**: Add Gmail app password to pass: `pass insert email/bgovedur@gmail.com`
    - Get app password from: https://myaccount.google.com/apppasswords
    - Create "Mail" app password (16 characters)
  - [ ] **TODO**: Run initial sync: `mbsync -a` (will take 5-10 min first time)
  - [ ] **TODO**: Add other accounts (benedikt@klifursamband.is, afreksnefnd@klifursamband.is) to `.mbsyncrc`
  - [ ] **TODO**: Set up notmuch for email indexing and search
  - [ ] **Reference**: See `/home/bgo/notes/bgovault/2.Areas/Linux/NeoMutt_Email_System_Guide.md`
- **Ranger**: Minimal configuration (only rc.conf), needs proper setup
- **Google Drive MCP (KÍ)**: OAuth credentials for `@modelcontextprotocol/server-gdrive`
  - [x] **DONE**: OAuth credentials backed up to `pass` (2026-02-18)
    - `pass show mcp/gdrive-oauth-keys` — Google Cloud client keys (project: KI-drive, ID: 313326843952)
    - `pass show mcp/gdrive-credentials` — OAuth refresh token (regenerable via OAuth flow)
    - MCP server config in `~/.claude.json` (project: `/home/bgo/personal/klifur/KI/fjarmal`)
    - Google account: KÍ Drive (benedikt@klifursamband.is)
    - Scope: `drive.readonly` only
    - **Restore after reinstall**:
      ```bash
      mkdir -p ~/.config/mcp-gdrive
      pass show mcp/gdrive-oauth-keys > ~/.config/mcp-gdrive/gcp-oauth.keys.json
      # Run the MCP server once to trigger OAuth flow for fresh refresh token
      ```

