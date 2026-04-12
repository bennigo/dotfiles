# system_files

Deploys curated system configuration files to `/etc` and `/usr`: udev rules, modprobe
configs, systemd units, desktop session files, and optionally fstab/hosts entries.

## When to run

After `base`. Needed for hardware-specific kernel settings and desktop session support.

```bash
ansible-playbook bootstrap.yml --tags system
```

## What it configures

- udev rules (MTP automount, input devices)
- modprobe configs (NVIDIA DRM, other kernel modules)
- systemd units (udevmon, custom services)
- Desktop session files for display managers
- Optional: custom fstab entries, /etc/hosts additions

## Dependencies

- `base`

## Key variables

- `deploy_custom_fstab` — enable custom fstab entries (default: false)
- `deploy_custom_hosts` — enable custom /etc/hosts (default: false)

## Verification

```bash
ls /etc/systemd/system/udevmon.service
udevadm info --query=all --name=/dev/input/event0 | head
```

## See also

- [`../../system/CLAUDE.md`](../../system/CLAUDE.md) — system-level configuration details
