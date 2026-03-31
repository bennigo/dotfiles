# CLAUDE.md

Personal dotfiles repository for Sway-based Linux desktop environment.
Uses modular GNU Stow deployment and hub-and-spoke documentation.

## Documentation Architecture

This repo uses hierarchical CLAUDE.md organization — detailed context lives in subdirectory
files; this file is the routing table. See `~/.claude/CLAUDE.md` for the full context
architecture guidelines. Subdirectories with their own CLAUDE.md are marked with `📄` below.

## System Environment

- **Hardware**: ThinkPad P1 Gen 6, NVIDIA RTX 2000 Ada (8GB VRAM)
- **OS**: Linux (Ubuntu-based), kernel 6.14.0-37-generic, x86_64
- **Desktop**: Sway (Wayland) + Waybar + Rofi + Mako + Kitty/Foot
- **Package managers**: apt, snap, flatpak

## Directory Structure

```
.dotfiles/
├── sway/           # Sway compositor — see sway/.config/sway/CLAUDE.md 📄
├── waybar/         # Status bar with custom modules — see waybar/CLAUDE.md 📄
├── neovim/         # LazyVim-based IDE (75+ plugins) — see neovim/.config/nvim/CLAUDE.md 📄
├── neovim_old/     # Previous neovim configuration backup
├── tmux/           # Terminal multiplexer + plugins — see tmux/.config/tmux/CLAUDE.md 📄
├── local_bin/      # Custom executable scripts (~28 scripts) — see local_bin/CLAUDE.md 📄
├── system/         # System configs, hardware, installation — see system/CLAUDE.md 📄
├── ansible/        # System provisioning and automation — see ansible/CLAUDE.md 📄
├── systemd/        # User systemd services (8 units) — see systemd/CLAUDE.md 📄
├── docker/         # Docker Engine + compose templates — see docker/CLAUDE.md 📄
├── claude-code/    # Claude Code CLI + MCP servers — see claude-code/CLAUDE.md 📄
├── firefox/        # Multi-profile Firefox + Sway workspace integration — see firefox/CLAUDE.md 📄
├── kitty/          # Terminal emulator (primary)
├── foot/           # Lightweight terminal emulator
├── alacritty/      # Cross-platform terminal emulator
├── qutebrowser/    # Keyboard-driven web browser
├── zsh/            # Shell configuration (Zap plugins, aliases) — see zsh/CLAUDE.md 📄
├── profile/        # Shell profile settings
├── ollama/         # Local LLM config (DeepSeek Coder V2, Llama 3.1) — see ollama/README.md
├── swappy/         # Screenshot annotation tool
├── grim/           # Screenshot tool (integrates with swappy/slurp)
├── mako/           # Notification daemon configuration
├── containers/     # Container/Podman configuration (minimal)
├── gnupg/          # GPG agent configuration (stow deploys to ~/.gnupg/)
├── luacheck/       # Lua linter configuration for Neovim development
├── udev/           # Device rules (MTP automount, input devices)
├── ranger/         # File manager (minimal, needs setup)
├── neomutt/        # Email client (needs post-reinstall setup — see system/CLAUDE.md)
├── claude-private/ # Encrypted submodule (git-crypt, GPG key 0FA08B1A9096B394) — stow-deployed
├── i3/             # Legacy i3 configuration (excluded from stow)
└── [app]/          # Per-application config directories
```

## Configuration Pattern

Each directory contains `.config/[app]` structure for GNU Stow deployment:

```bash
stow sway waybar neovim tmux   # Deploy multiple configs
stow -t ~ sway                 # Deploy single config
```

**Special cases:**
- `systemd/` — Must use `stow -R --no-folding systemd` (see `systemd/CLAUDE.md`)
- `claude-private/` — Encrypted submodule, intentionally stowed (deploys to `~/.claude/`)
- Subdirectory CLAUDE.md files use `.stow-local-ignore` to prevent deployment to `~/`

**Stow exclusions** (not stowed by Ansible):
`ansible/`, `system/`, `i3/`, `sway-remix/`, `systemd/` (separate), `.git/`, hidden dirs

## Key Features

### Smart Shortcut System
Sway config uses structured comments (`## Category // Description // Icon ##`) parsed by
`sway-shortcuts.sh` into searchable rofi menus. See `sway/.config/sway/CLAUDE.md`.

### Development Integration
- **Neovim**: LazyVim + Claude Code + Database UI + Obsidian — see `neovim/.config/nvim/CLAUDE.md`
- **Ollama**: GPU-accelerated local LLM inference — see `ollama/README.md`
- **PostgreSQL 18**: Secure credential management via `pass` — see `ansible/DATABASE_SETUP.md`
- **Docker 28.4.0**: Container orchestration with VPN-friendly networking — see `docker/CLAUDE.md`
- **Languages**: Python/uv, Go, Rust, Node.js/FNM, R

### System Automation
- **Ansible**: Profile-based bootstrap for fresh installations
- **Multi-machine sync**: `dotfiles-sync` script with Waybar indicators — see `SYNC_WORKFLOW.md`
- **Credentials**: Encrypted vault with GPG/pass integration
- **Systemd**: 8 user services for session automation — see `systemd/CLAUDE.md`

### Claude Code Integration
- **MCP servers**: Database access, web search — see `claude-code/CLAUDE.md`
- **Notifications**: Hook-based forwarding to Mako — see `claude-code/CLAUDE.md`
- **Remote control**: Tmux persistent window + Neovim keymap — see `tmux/.config/tmux/CLAUDE.md`

### Wayland Environment
- Tmux session env refresh after reboot — see `tmux/.config/tmux/CLAUDE.md`
- System-level fixes (Thunderbolt, VPN) — see `system/CLAUDE.md`

## Common Operations

```bash
# Deploy configurations
cd ~/.dotfiles && stow sway waybar neovim

# Sway
sway -C ~/.config/sway/config    # Test config
swaymsg reload                   # Reload

# Ansible bootstrap
cd ~/.dotfiles/ansible
ansible-playbook bootstrap.yml --extra-vars "profile=work_laptop"

# Database — see ansible/DATABASE_SETUP.md
psql bgo                         # Connect to default database

# Docker — see docker/CLAUDE.md
docker compose up -d             # Start services

# Sync — see SYNC_WORKFLOW.md
dotfiles-sync                    # Commit, pull, push all repos

# Script development
chmod +x ~/.local/bin/new_script.sh
```

## Script Dependencies

Common dependencies across custom scripts:
- rofi, jq, waybar, libnotify-bin (notify-send)
- playerctl (media control), pandoc + xelatex (PDF)
- arecord + faster-whisper (voice-input), wl-clipboard

## Development Notes

### Adding Configurations
1. Create directory with `.config/[app]` structure
2. Add application configs inside
3. If substantial, create a CLAUDE.md (see context architecture guidelines)
4. Deploy with `stow [app]`

### File Editing
Edit source files in this repository, not deployed locations in `~/.config/`.

## Cross-Reference Index

| File | Content |
|------|---------|
| `sway/.config/sway/CLAUDE.md` | Compositor config, workspaces, shortcuts, scratchpads |
| `neovim/.config/nvim/CLAUDE.md` | 75+ plugins, AI integration, database UI, keymaps |
| `tmux/.config/tmux/CLAUDE.md` | Session management, plugins, Wayland env fix, remote control |
| `docker/CLAUDE.md` | Daemon config, VPN networking, scripts, compose templates |
| `claude-code/CLAUDE.md` | MCP servers, notification hooks, remote control |
| `systemd/CLAUDE.md` | 8 user service units, deployment, activation |
| `zsh/CLAUDE.md` | Zap plugins, aliases, exports, Wayland env fix, stow conflict |
| `waybar/CLAUDE.md` | Modules, git-sync status, custom scripts, clipboard |
| `system/CLAUDE.md` | Hardware fixes, GPU, credentials, installation, post-reinstall TODOs |
| `firefox/CLAUDE.md` | Multi-profile setup, deploy script, Sway workspace integration |
| `local_bin/CLAUDE.md` | ~28 scripts by category, dependencies, adding new scripts |
| `ansible/CLAUDE.md` | Profile-based provisioning, 10 roles, hardware detection |
| `ollama/README.md` | Local LLM setup (DeepSeek, Llama), GPU configuration |
| `ansible/DATABASE_SETUP.md` | PostgreSQL 18 setup, credential management |
| `SYNC_WORKFLOW.md` | Multi-machine sync architecture |
| `SYNC_DEPLOYMENT.md` | Sync system deployment guide |
| `/home/bgo/CLAUDE.md` | Global workspace context |
