# dotfiles

Personal dotfiles for a Sway-based Linux desktop environment. Modular
[GNU Stow](https://www.gnu.org/software/stow/) deployment with Ansible-driven
bootstrap for fresh machines. Runs on Ubuntu 26.04 (Resolute Raccoon) and 24.04 LTS.

## Quick links

| I want to…                                    | Start here                                     |
| --------------------------------------------- | ---------------------------------------------- |
| **Set up a fresh machine**                    | [`ansible/FIRST_RUN.md`](ansible/FIRST_RUN.md) |
| **Choose a profile / decide what to install** | [`PLAYBOOK_GUIDE.md`](PLAYBOOK_GUIDE.md)       |
| **Understand the module structure**           | [`CLAUDE.md`](CLAUDE.md)                       |
| **Deploy configs on an existing system**      | See [Stow deployment](#stow-deployment) below  |
| **Sync dotfiles between machines**            | [`SYNC_WORKFLOW.md`](SYNC_WORKFLOW.md)         |

## What's in this repo

```
.dotfiles/
├── sway/        Sway compositor (Wayland)
├── waybar/      Status bar + custom modules
├── neovim/      LazyVim IDE (75+ plugins)
├── tmux/        Terminal multiplexer + plugins
├── zsh/         Shell (Zap plugins, aliases)
├── kitty/       Terminal emulator (primary)
├── foot/        Lightweight terminal
├── claude-code/ Claude Code CLI + MCP servers
├── crush/       Multi-provider AI coding TUI
├── docker/      Docker Engine + compose templates
├── systemd/     User systemd services (8 units)
├── ansible/     System provisioning (10 roles, 9 profiles)
├── local_bin/   ~28 custom scripts
├── system/      System configs + credential management
├── firefox/     Multi-profile + Sway workspace integration
├── ollama/      Local LLM inference (GPU-accelerated)
└── ...          Plus smaller modules (mako, grim, gnupg, etc.)
```

Each module deploys via `stow <module>`. Detailed documentation lives in each
module's `CLAUDE.md` — the top-level [`CLAUDE.md`](CLAUDE.md) is the routing table
linking all of them.

## Stow deployment

```bash
cd ~/.dotfiles

# Deploy individual modules
stow sway waybar neovim tmux zsh kitty

# Special cases
stow -R --ignore='\.zshenv' zsh      # known .zshenv conflict
stow -R --no-folding systemd         # prevent .wants/ symlinks in repo
```

See [`STOW_ORDER.md`](STOW_ORDER.md) for dependency ordering and common conflicts.

## Ansible bootstrap

For fresh machines, the Ansible playbook installs packages, configures services,
deploys dotfiles via Stow, and handles hardware-specific setup (NVIDIA GPU, laptop
power management).

```bash
cd ~/.dotfiles/ansible
ansible-playbook bootstrap.yml --extra-vars "profile=work_laptop" --ask-become-pass
```

Choose a profile: see [`PLAYBOOK_GUIDE.md`](PLAYBOOK_GUIDE.md) for the decision tree,
profile matrix, and step-by-step recipes for common scenarios.

## Documentation map

| File                                                           | Purpose                                             |
| -------------------------------------------------------------- | --------------------------------------------------- |
| [`CLAUDE.md`](CLAUDE.md)                                       | Hub for per-module documentation (AI agent context) |
| [`PLAYBOOK_GUIDE.md`](PLAYBOOK_GUIDE.md)                       | Decision tree, profile comparison, setup recipes    |
| [`STOW_ORDER.md`](STOW_ORDER.md)                               | Module deployment order, dependencies, conflicts    |
| [`SYNC_WORKFLOW.md`](SYNC_WORKFLOW.md)                         | Multi-machine sync architecture                     |
| [`SYNC_DEPLOYMENT.md`](SYNC_DEPLOYMENT.md)                     | Sync system deployment guide                        |
| [`ansible/FIRST_RUN.md`](ansible/FIRST_RUN.md)                 | Fresh 26.04 two-phase bootstrap procedure           |
| [`ansible/README.md`](ansible/README.md)                       | Full Ansible usage guide                            |
| [`ansible/INSTALL.md`](ansible/INSTALL.md)                     | Detailed installation walkthrough                   |
| [`ansible/DATABASE_SETUP.md`](ansible/DATABASE_SETUP.md)       | PostgreSQL 18 setup + credential management         |
| [`system/credentials.md`](system/credentials.md)               | GPG / Pass / Ansible Vault workflow                 |
| [`system/emergency-recovery.md`](system/emergency-recovery.md) | Credential lockout recovery                         |

---

_Last reviewed: 2026-04-11_
