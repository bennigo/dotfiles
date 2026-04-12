# Recovery & Troubleshooting

Common failure scenarios and how to recover from them. For credential-specific lockouts,
see [`system/emergency-recovery.md`](system/emergency-recovery.md).

## Stow conflicts

### `.zshenv` conflict (known, permanent)

```bash
stow -R --ignore='\.zshenv' zsh
```

A pre-existing `~/.zshenv` conflicts with stow. The `--ignore` flag skips it. This is
a known workaround — don't try to fix it, just use the flag.

### Generic "existing target" conflict

```bash
# See what's conflicting:
stow --no --verbose sway 2>&1 | grep "existing target"

# If the target is an old file (not a symlink), back it up:
mv ~/.config/sway/config ~/.config/sway/config.bak
stow sway
```

### Systemd stow conflict (`.wants/` directory)

```bash
# Always use --no-folding for systemd:
stow -R --no-folding systemd

# If already broken, un-stow first:
stow -D systemd
stow -R --no-folding systemd
```

See [`STOW_ORDER.md`](STOW_ORDER.md) for the full explanation.

## Bootstrap failures

### Ansible halted mid-run

Ansible is idempotent — re-run the same command. Completed tasks will be skipped.

```bash
cd ~/.dotfiles/ansible
ansible-playbook bootstrap.yml --extra-vars "profile=work_laptop" --ask-become-pass
```

### Apt package failures

```bash
# Fix broken packages:
sudo dpkg --configure -a
sudo apt --fix-broken install

# If a specific repo is broken (e.g., PostgreSQL PGDG):
sudo rm /etc/apt/sources.list.d/pgdg.list
sudo apt update
# Re-run the database role:
ansible-playbook bootstrap.yml --tags database --ask-become-pass
```

### Permission errors during stow

```bash
# Check ownership:
ls -la ~/.config/
# Fix if root owns something that should be user-owned:
sudo chown -R $USER:$USER ~/.config/
```

## Credential problems

### "UNABLE TO DECRYPT" in credentials role

The ansible-vault password is wrong or unavailable.

```bash
# Verify the vault password script works:
~/.dotfiles/system/scripts/ansible-vault-pass.sh
# Should print the password. If it fails:
pass show ansible/vault-password  # is the pass store initialized?
gpg --list-secret-keys            # is the GPG key imported?
```

### Lost GPG key

See [`system/emergency-recovery.md`](system/emergency-recovery.md) for USB backup
and paperkey recovery procedures.

### SSH key not working after bootstrap

```bash
# Check if credentials role extracted it:
ls -la ~/.ssh/id_*
# If missing, re-run credentials:
ansible-playbook bootstrap.yml --tags credentials --ask-become-pass
# Or restore from old machine:
rsync -av oldmachine:~/.ssh/ ~/.ssh/
chmod 700 ~/.ssh && chmod 600 ~/.ssh/id_*
```

## Desktop / Wayland issues

### Sway won't start after reboot

```bash
# Validate config:
sway -C ~/.config/sway/config

# Check if sway is installed:
which sway

# Try starting manually from TTY:
WLR_DRM_DEVICES=/dev/dri/card0 sway
```

### NVIDIA driver issues

```bash
# Check if driver loaded:
nvidia-smi

# If "command not found", reinstall:
ansible-playbook bootstrap.yml --tags nvidia --ask-become-pass \
  --extra-vars "force_nvidia=true nvidia_driver_version=590"

# If driver loads but sway crashes, check DRM:
cat /sys/module/nvidia_drm/parameters/modeset  # should be "Y"
```

### Blank screen / wrong monitor

```bash
# List outputs from TTY (SSH in, or switch to TTY with Ctrl+Alt+F2):
swaymsg -t get_outputs

# Disable a problematic output:
swaymsg output DP-1 disable
```

## Systemd service failures

```bash
# Check all user services:
systemctl --user list-units --state=failed

# Read logs for a specific service:
journalctl --user -u claude-imports -n 50

# Restart:
systemctl --user restart claude-imports

# If the service file is missing, re-stow:
stow -R --no-folding systemd
systemctl --user daemon-reload
systemctl --user enable --now claude-imports
```

## Un-doing a bad stow deployment

```bash
# Remove symlinks for one module (does NOT delete source files):
stow -D <module>

# Verify:
ls -la ~/.config/<app>/  # should show no symlinks

# Re-deploy after fixing:
stow <module>
```

## Full system reset (last resort)

If the system is unrecoverably broken and you want to start fresh:

```bash
# On the broken machine, make sure dotfiles are pushed:
cd ~/.dotfiles && git push

# Then reinstall Ubuntu, and follow FIRST_RUN.md or MIGRATION.md
```

Your data lives in git (dotfiles, bgovault, password-store). As long as the GPG key
is safe, everything is recoverable.

---

*Last reviewed: 2026-04-11*
