# Ansible System Provisioning

Profile-based bootstrap system for automated Ubuntu/Linux setup with hardware detection.

## Quick Start

```bash
cd ~/.dotfiles/ansible
ansible-playbook bootstrap.yml --extra-vars "profile=work_laptop"
```

## Installation Profiles

| Profile | Roles | Use Case |
|---------|-------|----------|
| `user` | base, dotfiles | Additional user setup (lightweight) |
| `minimal` | base, email, dotfiles | Headless/server |
| `development` | base, system_files, development, database, docker, dotfiles | Dev environment |
| `desktop` | base, system_files, development, database, docker, desktop, email, dotfiles | Full desktop |
| `full` | All including credentials | Complete setup |
| `work_laptop` | Full + work tools + NVIDIA + laptop | Primary work machine |
| `work_only` | Development without desktop/email | Work headless |
| `agent_server` | base, credentials, docker, dotfiles, agent | OpenClaw AI agent server |

**Tag-based selective runs:**
```bash
ansible-playbook bootstrap.yml --tags "development"   # Dev tools only
ansible-playbook bootstrap.yml --tags "database"       # PostgreSQL only
ansible-playbook bootstrap.yml --tags "dotfiles"       # Stow deployment only
ansible-playbook bootstrap.yml --tags "credentials"    # Vault management only
```

## Roles (10)

| Role | Purpose |
|------|---------|
| `base` | Essential packages, user groups, passwordless sudo |
| `system_files` | Deploy /etc and /usr configs, udev rules, systemd services |
| `development` | Language runtimes (Go, Rust, Node.js, Python), dev tools, CLI utilities |
| `database` | PostgreSQL from official repo, credential management via pass |
| `docker` | Official Docker Engine installation (not docker.io) |
| `desktop` | Sway + Wayland ecosystem (Waybar, Rofi, Mako, grim, etc.) |
| `credentials` | GPG, pass, ansible-vault preparation (no sensitive data in repo) |
| `dotfiles` | GNU Stow deployment of all config directories |
| `email` | NeoMutt setup, HTML email support, mail directory structure |
| `agent` | OpenClaw AI agent: isolated user, Node.js, Tailscale, UFW, API keys, bgovault read-only |
| `hardware/` | Sub-roles: `nvidia/` (GPU drivers), `laptop/` (TLP, brightness), `desktop/` (PulseAudio) |

## Hardware Auto-Detection

The playbook automatically detects and configures:
- **NVIDIA GPU** — PCI scan triggers driver installation + DRM kernel mode setting
- **Laptop vs Desktop** — Battery presence enables TLP power management
- **CPU architecture** — Intel/AMD-specific optimizations

Hardware roles can be manually overridden via `--extra-vars`.

## Key Variables (`group_vars/all.yml`)

- `target_user` — Auto-detected from `$USER`
- `target_email` — Default: bgo@vedur.is
- `profiles` — 7 predefined installation combinations
- `hardware_roles` — Conditional: nvidia, laptop, desktop
- `features` — Toggle flags: development, desktop, gaming, media, credentials, work

## Design Principles

- **Idempotent**: Safe to run multiple times
- **User-agnostic**: Auto-detects target user (bgo-specific features are flagged/conditional)
- **Profile-based**: Choose complexity level for the target machine
- **Two-phase credentials**: System preparation first, sensitive data via separate vault step

## Documentation

| File | Content |
|------|---------|
| `README.md` | Full usage guide (276 lines) |
| `INSTALL.md` | Step-by-step installation walkthrough |
| `TESTING.md` | Testing procedures |
| `DATABASE_SETUP.md` | PostgreSQL 18 setup and credential management |

## Cross-References

- **Stow deployment details**: `../CLAUDE.md` (configuration pattern, exclusions)
- **Systemd services**: `../systemd/CLAUDE.md` (enabled after dotfiles deployment)
- **System files**: `../system/CLAUDE.md` (hardware config, credential management)
- **Database credentials**: `DATABASE_SETUP.md`
- **Top-level overview**: `../CLAUDE.md`
