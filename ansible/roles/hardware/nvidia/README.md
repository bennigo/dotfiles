# hardware/nvidia

NVIDIA GPU driver installation. Auto-detected via PCI scan — only runs when an NVIDIA
GPU is present (or `force_nvidia=true`). Installs drivers and enables DRM kernel mode
setting via modprobe.

## When to run

Auto-triggered by hardware detection. Override with:

```bash
ansible-playbook bootstrap.yml --extra-vars "force_nvidia=true"
ansible-playbook bootstrap.yml --extra-vars "nvidia_driver_version=590"
```

## What it installs

- `nvidia-driver-<version>`, `nvidia-utils-<version>` (version pinned in `group_vars/all.yml`)
- modprobe config: `nvidia-drm modeset=1`

## Key variables

- `nvidia_driver_version` — default `"580"` (may need `590` on Ubuntu 26.04)
- `hardware_roles.nvidia.enabled` — auto-detected or force-overridden

## Verification

```bash
nvidia-smi
cat /sys/module/nvidia_drm/parameters/modeset  # should be "Y"
```
