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

### MTP Device Automounting (YoloBox, etc.)

Automatic mounting of MTP devices (Android-based devices like YoloBox) to convenient paths in `/media/$USER/`.

**Components:**
- `~/.local/bin/mtp-automount` - Main automount script
- `~/.local/bin/mount-yolobox` / `umount-yolobox` - Convenience wrappers
- `/etc/udev/rules.d/99-mtp-automount.rules` - Udev rules for auto-detection
- `/usr/local/bin/mtp-automount-helper` - Udev helper script
- `~/.config/systemd/user/mtp-automount@.service` - Systemd user service

**Installation:**
```bash
# Deploy system files (requires sudo)
sudo cp ~/.dotfiles/system/etc/udev/rules.d/99-mtp-automount.rules /etc/udev/rules.d/
sudo cp ~/.dotfiles/system/usr/local/bin/mtp-automount-helper /usr/local/bin/
sudo chmod +x /usr/local/bin/mtp-automount-helper
sudo udevadm control --reload-rules

# User files are deployed via stow (local_bin, systemd)
cd ~/.dotfiles && stow local_bin systemd
systemctl --user daemon-reload
```

**Usage:**
```bash
mtp-automount mount              # Mount first available MTP device
mtp-automount mount YoloBox      # Mount YoloBox specifically
mtp-automount unmount YoloBox    # Unmount YoloBox
mtp-automount list               # List known devices
mtp-automount status             # Show mount status

# Or use convenience wrappers:
mount-yolobox
umount-yolobox
```

**Adding new devices:** Edit `~/.local/bin/mtp-automount` and add entries to `MTP_DEVICES` array.

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