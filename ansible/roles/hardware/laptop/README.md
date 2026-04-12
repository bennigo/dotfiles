# hardware/laptop

Laptop power management. Auto-detected via battery presence — only runs on laptops
(or `force_laptop=true`). Installs TLP, configures CPU governor switching, and sets
up brightness control via sudoers.

## When to run

Auto-triggered by hardware detection.

```bash
ansible-playbook bootstrap.yml --extra-vars "force_laptop=true"
```

## What it installs

- `tlp`, `tlp-rdw`, `powertop`, `brightnessctl`
- TLP daemon config (performance on AC, powersave on battery)
- Sudoers rule for `brightnessctl` without password

## Key variables

- `hardware_roles.laptop.enabled` — auto-detected or force-overridden
- `hardware_roles.laptop.packages`, `hardware_roles.laptop.services`

## Verification

```bash
systemctl status tlp
tlp-stat -s | head
sudo brightnessctl get
```
