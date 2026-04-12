# hardware/desktop

Desktop audio system configuration. Installs PulseAudio with sane defaults (16-bit LE,
44.1 kHz, stereo). Runs on non-laptop systems by default.

## When to run

Auto-triggered when `hardware_roles.desktop.enabled` is true (default on non-laptops).

## What it installs

- `pulseaudio`, `pulseaudio-utils`
- `daemon.conf` with format/rate/channels pinned

## Key variables

- `hardware_roles.desktop.enabled` — auto-detected
- `hardware_roles.desktop.packages`

## Verification

```bash
pactl info | grep "Server Name"
systemctl --user status pulseaudio
```
