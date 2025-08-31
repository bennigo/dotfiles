# System Installation and Configuration

This file provides system-specific installation procedures, hardware configuration, and credential management for the dotfiles repository. For general repository usage, see the main `CLAUDE.md` file.

## System Installation and Setup

### Initial System Setup (`install.txt`)
Complete installation procedures including:
- System packages and dependencies
- Development environments (Node.js, Rust, Python, etc.)
- Desktop environment components
- Custom tools and utilities

### System Files Structure
- **`/etc/`**: System configuration files (fstab, hosts, modprobe.d, systemd services)
- **`/usr/share/wayland-sessions/`**: Desktop session files
- **`scripts/`**: System management and automation scripts
- **Credentials management**: Ansible Vault integration with GPG/pass

### Hardware and Performance Configuration

#### GPU Configuration
- **Nvidia support**: Custom modprobe configuration (`nvidia-drm.conf`)
- **DRM kernel mode setting**: Early KMS for Wayland compatibility
- **Performance testing**: Validation scripts (`nvidia.test`)

#### Input Device Management
- **Custom udev rules**: Advanced input device handling (`udevmon.yaml`)
- **Systemd service**: `udevmon.service` for persistent input customization
- **PAM environment**: Security and session management (`pam_env.conf`)

### Development Environment Setup

#### Programming Languages and Tools
- **Python**: Full scientific/development stack
- **Node.js**: Modern JavaScript development
- **Rust**: Systems programming toolkit
- **Shell**: Zsh with custom environment (`zshenv`)

#### Package Management
- **System packages**: apt-based installation
- **Development tools**: Language-specific package managers
- **Container support**: Podman/Docker configuration

## Common Commands

### System Installation
```bash
# Initial system setup (run once)
cd ~/.dotfiles/system/
# Follow install.txt for complete system installation

# Deploy system configurations
sudo cp etc/fstab /etc/fstab
sudo cp usr/share/wayland-sessions/sway.desktop /usr/share/wayland-sessions/
sudo systemctl enable udevmon.service
```

### Hardware Troubleshooting
```bash
# Test Nvidia configuration
./nvidia.test

# Input device debugging
udevadm monitor --environment --udev

# System service management
sudo systemctl status udevmon
sudo systemctl restart udevmon
```

### Credentials Management
Secure credential storage using Ansible Vault encryption with GPG/pass integration:

```bash
# Initial setup (run once)
./scripts/setup_vault.sh

# Edit credentials (opens in editor)
ansible-vault edit --vault-password-file ./scripts/ansible-vault-pass.sh credentials.vault

# Interactive credential management (recommended)
./scripts/add-credentials.sh
```

**Complete documentation**: 
- `credentials.md` - Main setup and usage guide
- `emergency-recovery.md` - Lockout prevention and recovery procedures  
- `gpg-pass-tutorial.md` - GPG and Pass refresher tutorial
- `password-memory-strategy.md` - Backup and memory techniques

## Cross-References

- **General repository usage**: See `../CLAUDE.md` for configuration deployment and common operations
- **Global workspace context**: See `/home/bgo/CLAUDE.md` for project context
- **Application configs**: Individual app directories for specific configurations