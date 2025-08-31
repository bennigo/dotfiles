# Installation Guide - Single Command Ubuntu Setup

Transform a fresh Ubuntu 25.04+ system into your complete development environment with one command.

## 🎯 Overview

This Ansible-based bootstrap system will automatically:
- Detect your hardware (NVIDIA GPU, laptop vs desktop)
- Install all packages from your `install.txt` (260+ lines automated)
- Deploy system configurations (`/etc/`, `/usr/` files)
- Set up development environment (Go, Rust, Node.js, Python)
- Configure Sway desktop with waybar
- Deploy all dotfiles via stow
- Set up credentials system (GPG + pass + ansible-vault)

## 🚀 Quick Start - Single Command Setup

On a **fresh Ubuntu 25.04+** system with sudo access:

```bash
# Install prerequisites and bootstrap system
sudo apt update && sudo apt install -y git ansible
git clone https://github.com/your-username/dotfiles.git ~/.dotfiles  
cd ~/.dotfiles/ansible
ansible-playbook bootstrap.yml -K
```

**That's it!** ✨ 

The system will:
1. Detect your hardware automatically
2. Ask for confirmation of detected settings  
3. Install ~45 minutes of packages and configuration
4. Suggest a reboot when complete

## 📋 What Gets Installed

### Core System
- **User setup**: zsh shell, sudo configuration, essential directories
- **System files**: udev rules, systemd services, desktop sessions
- **Input enhancement**: caps2esc key remapping

### Development Environment  
- **Languages**: Go 1.24.5, Rust (latest), Node.js (LTS), Python 3.12+
- **Package managers**: cargo, npm, pip, pipx, uv
- **Dev tools**: cmake, clangd, tmux, neovim dependencies
- **CLI tools**: eza, bat, ripgrep, zoxide, fd-find

### Desktop Environment
- **Compositor**: Sway with Wayland  
- **Status bar**: Waybar with custom modules
- **Launcher**: Rofi for applications/scripts
- **Terminal**: Foot with custom themes
- **Notifications**: Mako notifier
- **Screenshots**: Grim + Swappy workflow

### Hardware-Specific Setup
- **NVIDIA GPU**: Drivers, DRM kernel mode setting, nvidia-smi testing
- **Laptop**: TLP power management, brightness controls, battery optimization  
- **Desktop**: PulseAudio configuration, desktop peripherals

## 🎛️ Installation Options

### Profile-Based Installation

```bash
# Minimal headless setup (servers)
ansible-playbook bootstrap.yml --extra-vars "profile=minimal" -K

# Development environment only  
ansible-playbook bootstrap.yml --extra-vars "profile=development" -K

# Full desktop (default)
ansible-playbook bootstrap.yml --extra-vars "profile=desktop" -K

# Complete work laptop setup
ansible-playbook bootstrap.yml --extra-vars "@profiles/work_laptop.yml" -K
```

### Selective Installation

```bash
# Install only specific components
ansible-playbook bootstrap.yml --tags "base,development" -K

# Skip heavy packages (faster install)  
ansible-playbook bootstrap.yml --skip-tags "heavy" -K

# Only desktop environment
ansible-playbook bootstrap.yml --tags "desktop" -K
```

### Hardware Override

```bash
# Force NVIDIA setup (if detection fails)
ansible-playbook bootstrap.yml --extra-vars "force_nvidia=true" -K

# Force laptop optimizations
ansible-playbook bootstrap.yml --extra-vars "force_laptop=true" -K

# Skip all hardware-specific setup
ansible-playbook bootstrap.yml --skip-tags "hardware" -K
```

## 🔧 Prerequisites

### Minimum Requirements
- **OS**: Ubuntu 25.04+ (fresh installation recommended)
- **User**: Non-root user with sudo access
- **Network**: Internet connection for package downloads
- **Storage**: ~10GB free space for full installation

### Before You Start
1. **Clean system recommended**: Works best on fresh Ubuntu install
2. **Backup important data**: System files will be modified
3. **Network stability**: Large downloads during installation  
4. **Time**: Allow 30-45 minutes for full installation

## 🛡️ Security & Credentials

### Two-Phase Credential Setup

The bootstrap **prepares** the credential system but doesn't configure sensitive data:

**Phase 1 - Bootstrap (Automated)**:
- Installs GPG, pass, ansible
- Creates directory structure
- Sets up scripts

**Phase 2 - Credential Configuration (Manual)**:
```bash  
# After bootstrap completes:
cd ~/.dotfiles/system

# Set up GPG key and pass  
./scripts/setup_vault.sh

# Migrate existing credentials
python3 scripts/copy_credentials.py

# Encrypt credentials  
ansible-vault encrypt --vault-password-file ./scripts/ansible-vault-pass.sh credentials_populated.yml
mv credentials_populated.yml credentials.vault
```

### Why Two Phases?
- **Security**: Keeps sensitive setup separate from public bootstrap
- **Flexibility**: Bootstrap can be public, credentials stay private
- **Safety**: Manual credential setup prevents automation mistakes

## 🔍 Hardware Detection

The system automatically detects:

| Hardware | Detection Method | Automatic Setup |
|----------|------------------|----------------|
| NVIDIA GPU | PCI device scan | Drivers, DRM kernel mode |  
| Laptop/Desktop | Chassis/form factor | Power management vs desktop audio |
| Battery Present | Power supply scan | TLP optimization |
| Intel/AMD CPU | Processor info | Architecture-specific optimizations |

### Manual Override Examples
```bash
# Your laptop wasn't detected as laptop
--extra-vars "force_laptop=true"

# NVIDIA GPU not detected properly  
--extra-vars "force_nvidia=true"

# Skip all hardware detection
--extra-vars "skip_hardware_specific=true"
```

## 🚨 Troubleshooting

### Common Issues

**"Hardware not detected correctly"**
```bash
# Check what was detected
ansible localhost -m setup | grep -E "(nvidia|battery|chassis)"

# Override with manual flags
--extra-vars "force_nvidia=true force_laptop=true"
```

**"Package installation failed"**  
```bash
# Update package cache
sudo apt update

# Run with verbose output to identify problem
ansible-playbook bootstrap.yml -vvv -K
```

**"Permissions error"**
```bash
# Ensure user has sudo access
sudo usermod -aG sudo $USER

# Re-login to apply group changes
```

**"Sway won't start after installation"**
```bash  
# Reboot required for all changes
sudo reboot

# Check logs
journalctl --user -u sway
```

### Recovery Options

**Partial installation failure**:
```bash
# Resume from specific point
ansible-playbook bootstrap.yml --start-at-task "Install development packages" -K

# Skip failed components  
ansible-playbook bootstrap.yml --skip-tags "development" -K
```

**System rollback**:
- All system files are backed up during deployment
- Check `/etc/*.backup.*` files
- Dotfiles can be unstowed: `cd ~/.dotfiles && stow -D sway waybar`

## 📈 Customization

### Adding Custom Packages
```bash
# Add to installation
--extra-vars "additional_base_packages=['my-tool','another-tool']"  
```

### Custom Configuration
1. Edit `group_vars/all.yml` for permanent changes
2. Create `host_vars/localhost.yml` for machine-specific overrides
3. Use `--extra-vars` for one-time customizations

### Extending Hardware Support
1. Create new role in `roles/hardware/new_device/`
2. Add detection logic to `inventory.yml`  
3. Update `group_vars/all.yml` hardware_roles section

## 🎯 Post-Installation

### Immediate Steps
1. **Reboot system**: `sudo reboot`
2. **Log into Sway**: Select "Sway" from login manager
3. **Test key shortcuts**: `Mod+Return` (terminal), `Mod+d` (rofi)
4. **Configure credentials**: Follow credential setup above

### Verification Checklist
- [ ] Sway desktop loads properly
- [ ] Terminal opens (foot)  
- [ ] Application launcher works (rofi)
- [ ] File manager available (ranger)
- [ ] Development tools accessible (`go version`, `cargo --version`)
- [ ] Hardware-specific features work (brightness, NVIDIA, etc.)

### Next Steps  
- Set up credentials system
- Configure personal git repositories
- Install additional software as needed
- Customize Sway/waybar themes
- Set up work-specific tools and VPNs

## 📞 Support

### Documentation
- **Ansible roles**: Check `roles/*/README.md` for role-specific docs
- **Credential system**: See `system/credentials.md`  
- **Emergency recovery**: See `system/emergency-recovery.md`

### Common Commands
```bash  
# View installation log
journalctl -u ansible-playbook

# Test hardware detection
ansible localhost -m setup

# Re-run specific role
ansible-playbook bootstrap.yml --tags "desktop" -K
```

The bootstrap system is designed to be **idempotent** - safe to run multiple times. If something fails, fix the issue and re-run the playbook.

---

**Transform time**: Fresh Ubuntu → Complete development environment in **~45 minutes** ⚡