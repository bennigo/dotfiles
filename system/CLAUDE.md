# System Installation and Configuration

System-level configs, hardware setup, credential management, and installation procedures
for the dotfiles repository. For general repository usage, see the main `CLAUDE.md`.

## System Environment

- **Hardware**: ThinkPad P1 Gen 6
- **OS**: Linux (Ubuntu-based), kernel 6.14.0-37-generic, x86_64
- **GPU**: NVIDIA RTX 2000 Ada (8GB VRAM) with proprietary drivers
- **Thunderbolt**: Intel Maple Ridge TB4 controller
- **Package managers**: apt, snap, flatpak

## Directory Structure

- **`/etc/`**: System configuration files (fstab, hosts, modprobe.d, systemd services)
- **`/usr/share/wayland-sessions/`**: Desktop session files
- **`scripts/`**: System management and automation scripts
- **`install.txt`**: Complete installation procedures

## System-Level Fixes

### Thunderbolt 4 Resume Fix
**File**: `usr/lib/systemd/system-sleep/thunderbolt-fix`

Fixes Intel Maple Ridge Thunderbolt 4 D3cold hang post-resume on ThinkPad P1 Gen 6.
Removes and rescans PCI bridge `0000:20:00.0` as a systemd sleep hook.

### Cisco VPN Local Route Fix
**File**: `etc/NetworkManager/dispatcher.d/99-fix-vpn-local-routes`

Bypasses Cisco AnyConnect VPN hijacking of local subnet routes. Uses policy routing (table 200)
+ iptables RETURN rules with device whitelist (router, printer, etc.). Auto-retries to survive
vpnagentd chain rebuilds.

## GPU / Nvidia Configuration

- **Modprobe**: `nvidia-drm.conf` enables DRM kernel mode setting (early KMS for Wayland)
- **Performance testing**: `nvidia.test` validation script
- **Wayland compatibility**: Early KMS required for optimal Sway performance

```bash
# Check GPU status
nvidia-smi
swaymsg -t get_outputs

# Test Nvidia configuration
./nvidia.test
```

## Wayland Compatibility

- **XWayland**: Legacy X11 application support enabled in Sway
- **Screen sharing**: Portal-based sharing for Wayland applications (xdg-desktop-portal-wlr)
- **Clipboard**: wl-clipboard for Wayland-native copy/paste
- **Environment**: PAM-based XDG configuration for consistent path resolution

## Input Device Management

- **Custom udev rules**: Advanced input device handling (`udevmon.yaml`)
- **Systemd service**: `udevmon.service` for persistent input customization
- **PAM environment**: Security and session management (`pam_env.conf`)

```bash
# Input device debugging
udevadm monitor --environment --udev

# Service management
sudo systemctl status udevmon
sudo systemctl restart udevmon
```

## MTP Device Automounting

Automatic mounting of MTP devices (Android-based devices like YoloBox) to `/media/$USER/`.

### Components
- `~/.local/bin/mtp-automount` — Main automount script
- `~/.local/bin/mount-yolobox` / `umount-yolobox` — Convenience wrappers
- `/etc/udev/rules.d/99-mtp-automount.rules` — Udev rules for auto-detection
- `/usr/local/bin/mtp-automount-helper` — Udev helper script
- `~/.config/systemd/user/mtp-automount@.service` — Systemd template service

### Installation
```bash
sudo cp ~/.dotfiles/system/etc/udev/rules.d/99-mtp-automount.rules /etc/udev/rules.d/
sudo cp ~/.dotfiles/system/usr/local/bin/mtp-automount-helper /usr/local/bin/
sudo chmod +x /usr/local/bin/mtp-automount-helper
sudo udevadm control --reload-rules
```

### Usage
```bash
mtp-automount mount              # Mount first available MTP device
mtp-automount mount YoloBox      # Mount YoloBox specifically
mtp-automount unmount YoloBox    # Unmount YoloBox
mtp-automount list               # List known devices
```

**Adding new devices**: Edit `~/.local/bin/mtp-automount` and add entries to `MTP_DEVICES` array.

## Credentials Management

Secure credential storage using Ansible Vault encryption with GPG/pass integration:

```bash
# Initial setup
./scripts/setup_vault.sh

# Edit credentials
ansible-vault edit --vault-password-file ./scripts/ansible-vault-pass.sh credentials.vault

# Interactive credential management (recommended)
./scripts/add-credentials.sh
```

**Documentation**:
- `credentials.md` — Main setup and usage guide
- `emergency-recovery.md` — Lockout prevention and recovery
- `gpg-pass-tutorial.md` — GPG and Pass refresher
- `password-memory-strategy.md` — Backup and memory techniques

## Initial System Setup

Follow `install.txt` for complete installation including:
- System packages and dependencies
- Development environments (Node.js, Rust, Python, Go, R)
- Desktop environment components (Sway, Waybar, Rofi, Mako)
- Custom tools and utilities

```bash
# Deploy system configurations
sudo cp etc/fstab /etc/fstab
sudo cp usr/share/wayland-sessions/sway.desktop /usr/share/wayland-sessions/
sudo systemctl enable udevmon.service
```

## Configuration Gaps (Post-Reinstall TODO)

### Neomutt Email Setup
Structure present, needs configuration after laptop reinstallation:
- [ ] mbsync setup: `.mbsyncrc` created for Gmail
- [ ] Add Gmail app password: `pass insert email/bgovedur@gmail.com`
  - Get from: https://myaccount.google.com/apppasswords (create "Mail" app password)
- [ ] Run initial sync: `mbsync -a` (5-10 min first time)
- [ ] Add accounts: benedikt@klifursamband.is, afreksnefnd@klifursamband.is
- [ ] Set up notmuch for email indexing and search
- [ ] Reference: `~/notes/bgovault/2.Areas/Linux/NeoMutt_Email_System_Guide.md`

### Ranger File Manager
Minimal configuration (only rc.conf), needs proper setup.

### Google Drive MCP (KÍ)
OAuth credentials for `@modelcontextprotocol/server-gdrive`:
- [x] OAuth credentials backed up to `pass` (2026-02-18)
  - `pass show mcp/gdrive-oauth-keys` — Google Cloud client keys (project: KI-drive)
  - `pass show mcp/gdrive-credentials` — OAuth refresh token
  - Google account: KÍ Drive (benedikt@klifursamband.is), scope: `drive.readonly`
- **Restore after reinstall**:
  ```bash
  mkdir -p ~/.config/mcp-gdrive
  pass show mcp/gdrive-oauth-keys > ~/.config/mcp-gdrive/gcp-oauth.keys.json
  # Run the MCP server once to trigger OAuth flow for fresh refresh token
  ```

## Cross-References

- **General repository usage**: `../CLAUDE.md`
- **Ansible provisioning**: `../ansible/` (bootstrap, DATABASE_SETUP.md)
- **Systemd services**: `../systemd/CLAUDE.md`
- **MTP scripts**: `../local_bin/` (mtp-automount, mount-yolobox)
- **Global workspace context**: `/home/bgo/CLAUDE.md`
