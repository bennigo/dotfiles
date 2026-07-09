# System Installation and Configuration

System-level configs, hardware setup, credential management, and installation procedures
for the dotfiles repository. For general repository usage, see the main `CLAUDE.md`.

## System Environment

- **Hardware**: ThinkPad P1 Gen 6
- **OS**: Linux (Ubuntu 26.04 LTS "Resolute Ringtail"), kernel 6.17.0-22-generic, x86_64
- **GPU**: NVIDIA RTX 2000 Ada (8GB VRAM) with open kernel drivers (nvidia-driver-595-open)
- **Thunderbolt**: Intel Maple Ridge TB4 controller
- **Package managers**: apt, snap, flatpak

## Directory Structure

- **`/etc/`**: System configuration files (fstab, hosts, modprobe.d, systemd services)
- **`/usr/share/wayland-sessions/`**: Desktop session files
- **`scripts/`**: System management and automation scripts
- **`install.txt`**: Complete installation procedures

## System-Level Fixes

### Power Management

**Files**:
- `etc/UPower/UPower.conf` — critical battery action
- `etc/udev/rules.d/99-lid-ac-suspend.rules` — AC-unplug + lid-closed suspend
- `local_bin/.local/bin/lid-ac-suspend-check` — helper called by udev rule

**Critical battery (suspend at 10% instead of poweroff)**:
- `PercentageAction=10.0` — triggers at 10%, not 2%
- `AllowRiskyCriticalPowerAction=true` + `CriticalPowerAction=Suspend`
- Without this the fallback chain (HybridSleep → Hibernate → PowerOff) reaches PowerOff when hibernation is not configured

**Lid closed while on AC, then charger unplugged**:
- The `lid-handler.sh` only fires on lid events, not power-state changes
- The udev rule fires on AC disconnect, checks `/proc/acpi/button/lid/*/state`, suspends if closed

**Deploy after reinstall**:
```bash
sudo mkdir -p /etc/UPower
sudo cp etc/UPower/UPower.conf /etc/UPower/UPower.conf
sudo cp etc/udev/rules.d/99-lid-ac-suspend.rules /etc/udev/rules.d/
sudo cp ~/.local/bin/lid-ac-suspend-check /usr/local/bin/
sudo chmod +x /usr/local/bin/lid-ac-suspend-check
sudo systemctl restart upower
sudo udevadm control --reload-rules
```

### NVIDIA Suspend jump_label Panic — FIXED in driver 595.71.05 (2026-06-18)

**Current driver**: `nvidia-driver-595-open` 595.71.05-0ubuntu0.26.04.1 (loaded module 595.71.05).
**GRUB_DEFAULT**: re-pinned to **7.0.0-22-generic** (2026-06-18) now that the panic is fixed.
Backup of the prior value: `/etc/default/grub.bak.before-7022-pin`.

The old jump_label panic (kernel BUG at `jump_label.c:73`, `nvkms_kthread_q_callback+0x8e`
in `nvidia_modeset.ko` during `freeze_processes()` on suspend) was **NOT a kernel regression
to wait out** — root cause was NVIDIA's DKMS build skipping objtool's NOP→JMP conversion
(NVIDIA open-gpu-kernel-modules issue #1095, `build-problem`). **The fix shipped inside the
driver package 595.71.05**, which is installed. Ubuntu bug 2150356 is still New/untriaged but
moot. Verified 2026-06-18: booted 7.0.0-22, `PM: suspend entry → suspend exit` clean, zero
`jump_label`/`kernel BUG`/panic in any journal boot, no `/var/crash` dumps.

There is **no pending kernel patch to monitor** — the kernel revert plan is obsolete.

GRUB now boots 7.0.0-22 by default. To fall back to 6.17 for one boot if ever needed:
`sudo grub-reboot "Advanced options for Ubuntu>Ubuntu, with Linux 6.17.0-22-generic"`.

### Touchpad Immediate-Wake on s2idle (suspend exits ~3s after entry)

**File**: `etc/udev/rules.d/90-disable-touchpad-wakeup.rules`

Separate bug from the jump_label panic above (do not conflate). On 7.0.0-x the ELAN I2C
touchpad (`i2c-ELAN0686:00`, IRQ 56) is armed as a wakeup source and fires an interrupt the
instant s2idle is reached → suspend exits ~3 seconds later. Diagnose after a failed suspend:
`cat /sys/power/pm_wakeup_irq` (→ 56) then map via `/proc/interrupts` (→ ELAN0686).

The udev rule sets `power/wakeup=disabled` on the touchpad. LID (lid-open) and SLPB (power
button) stay armed, so intended wake paths are unaffected. Reverting the kernel does NOT
reliably fix this — it's an ACPI/PCIe wakeup-flag issue, not the jump_label path.

**Deploy after reinstall**:
```bash
sudo cp etc/udev/rules.d/90-disable-touchpad-wakeup.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
echo disabled | sudo tee /sys/bus/i2c/devices/i2c-ELAN0686:00/power/wakeup
```

### Suspend-Failure Desktop Notifier (NFS/receivers blocks the freezer)

**Files**: `usr/local/bin/suspend-failed-notify`,
`etc/systemd/system/suspend-failed-notify.service`,
`etc/systemd/system/systemd-suspend.service.d/onfailure.conf`

Suspend can silently fail and leave the laptop **awake in the bag**. Root cause seen
2026-07-09: `receivers` (GPS processing) had threads in uninterruptible `D` state on
an NFS read (`ananas`/`granit` under `/mnt_data/*`) — `io_schedule -> filemap_read`.
The kernel freezer cannot stop D-state I/O, so after a 20s timeout suspend aborts with
*"Failed to put system to sleep. System resumed again: Device or resource busy"* and
`systemd-suspend.service` exits `1/FAILURE`. Diagnose:
`journalctl -k -b | grep -i 'refusing to freeze'`.

Rather than force sleep (risking GPS read errors), a drop-in wires
`OnFailure=suspend-failed-notify.service` onto `systemd-suspend.service`. On failure it
fires a **critical Mako notification** ("⚠ Suspend FAILED — laptop is still AWAKE") into
each active user session via `runuser … env DBUS_SESSION_BUS_ADDRESS=/run/user/<uid>/bus
notify-send`. So a failed suspend is now loud instead of silent.

Deployed by Ansible `system_files` role (tags: `suspend`,`notify`). Manual deploy:
```bash
sudo install -m0755 system/usr/local/bin/suspend-failed-notify /usr/local/bin/
sudo install -m0644 system/etc/systemd/system/suspend-failed-notify.service /etc/systemd/system/
sudo install -d /etc/systemd/system/systemd-suspend.service.d
sudo install -m0644 system/etc/systemd/system/systemd-suspend.service.d/onfailure.conf /etc/systemd/system/systemd-suspend.service.d/
sudo systemctl daemon-reload
sudo systemctl start suspend-failed-notify.service   # test the popup
```

### Thunderbolt 4 Resume Fix
**File**: `usr/lib/systemd/system-sleep/thunderbolt-fix`

Fixes Intel Maple Ridge Thunderbolt 4 D3cold hang post-resume on ThinkPad P1 Gen 6.
Removes and rescans PCI bridge `0000:20:00.0` as a systemd sleep hook.

### Bluetooth CNVi Power Issue (Runtime PM)
**Files**: `etc/udev/rules.d/99-tb4-xhci-pm.rules`

The Intel CNVi Bluetooth companion (attached to USB port 1-10 on xHCI 00:14.0) can become
permanently wedged in D3cold, requiring a **cold boot** to recover. The trigger is the
**TB4 xHCI controller (57:00.0, 8086:1138)** failing to resume from runtime D3cold with
`USBSTS 0x401`, which causes cascading PCI power transitions that briefly wake the CNVi
companion — followed by hundreds of failed enumeration attempts (`-71` protocol errors).

The `thunderbolt-fix` handles S3 suspend/resume, but this is a **runtime PM** issue.
The udev rule sets `power/control=on` on the TB4 USB controller to prevent it from
entering runtime suspend entirely.

**Symptoms**: `bluetoothctl show` says "No default controller available", no `hci0`
in `/sys/class/bluetooth/`, `CNVI_SCU_SEQ_DATA_DW9: 0x0` in dmesg.

**Recovery**: Cold boot. No runtime fix exists — the CNVi companion must
power-cycle. Toggling ThinkPad ACPI (`/proc/acpi/ibm/bluetooth`) or reloading
btusb/btintel modules will not help once the device is in this state.

**Deploy after reinstall**:
```bash
sudo cp etc/udev/rules.d/99-tb4-xhci-pm.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
```

### Bluetooth LE Audio (LC3 earbuds — e.g. JBL Tour Pro 3)
**Config**: `/etc/bluetooth/main.conf` — `Experimental = true` + `KernelExperimental = true`
**Ansible**: `roles/hardware/laptop` (tag `bluetooth`)

LE-Audio earbuds pair over BLE (Google Fast Pair) and expose **no classic A2DP
profile** unless BlueZ experimental features are enabled — so PipeWire has no audio
sink and there is no sound. Enabling the two flags (and restarting `bluetooth`)
lets the device negotiate audio.

If a bud was previously bonded LE-only you may see `br-connection-key-missing` on
connect — the classic link key is broken. Fix by re-pairing fresh:
```bash
bluetoothctl remove <MAC>           # drop the stale LE-only bond
# put earbuds in pairing mode (hold case button until LED blinks),
# disconnect them from any phone (multipoint steals the classic link)
bluetoothctl --timeout 30 scan on &
bluetoothctl pair <MAC>; bluetoothctl trust <MAC>; bluetoothctl connect <MAC>
wpctl status | grep -i bluez        # expect Active Profile: a2dp-sink
```

### Login / Boot Performance (SSSD removal + NFS automount)
**Ansible**: `roles/base` (tags `sssd`, `auth`, `filesystem`)

Two latent issues on fresh Ubuntu installs, both fixed in Ansible:

1. **SSSD lockout / slow prompt** — Ubuntu ships `sssd` + `libpam-sss` + `libnss-sss`
   pre-installed, wiring `sss` into NSS (`nsswitch.conf`) and PAM (`common-auth`).
   With no `/etc/sssd/sssd.conf` (not domain-joined) every login/lookup hits the
   dead SSSD socket and **times out ~30s** → `swaylock` can't unlock (forced reboot)
   and the shell prompt is delayed after boot. Fix: purge the sss packages
   (auto-cleans PAM via pam-auth-update) and strip `sss` from `nsswitch.conf`.
   Local `files` users don't need it.
2. **NFS mounts block boot** — the vedur.is `/mnt_data/*` NFS shares must use
   `nofail,_netdev,x-systemd.automount,x-systemd.mount-timeout=10` (NOT `nfs
   defaults`). Otherwise each blocks boot ~25s when off the network/VPN. Automount
   mounts them on first access instead.

Manual re-apply (if a reinstall restores defaults):
```bash
sudo apt purge -y 'sssd*' libpam-sss libnss-sss
sudo sed -i -E 's/[[:space:]]+sss\b//g' /etc/nsswitch.conf
# ensure /mnt_data/* fstab lines use nofail,_netdev,x-systemd.automount,...
sudo systemctl daemon-reload
```

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

---

*Last reviewed: 2026-04-11*
