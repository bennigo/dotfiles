# Systemd User Services

User systemd service units for session automation, deployed via GNU Stow.

## Stow Deployment

This package **must** use `--no-folding` to prevent stow from tree-folding `~/.config/systemd/`:

```bash
stow -R --no-folding systemd
```

Without `--no-folding`, `systemctl --user enable` would create `.wants/` symlinks inside the
git repo instead of in a real directory. Ansible handles this automatically during bootstrap.

## Service Units

| Unit | Type | Activation | Purpose |
|------|------|-----------|---------|
| `claude-imports.service` | Long-running | `enable --now` | Watches Downloads for vault notes and Claude exports |
| `mako-watcher.path` | Path trigger | `enable --now` | Triggers mako-watcher.service on config file changes |
| `mako-watcher.service` | Triggered | via `.path` | Reloads Mako notification daemon on config change |
| `password-store-sync.timer` | Timer | `enable --now` | Schedules periodic password store and dotfiles sync |
| `password-store-sync.service` | Triggered | via `.timer` | Runs the actual sync (git pull/push) |
| `tmux.service` | Forking | `enable` only | Starts detached tmux session at login |
| `spotify-notify.service` | Long-running | `enable --now` | Track change notifications via playerctl + notify-send |
| `mtp-automount@.service` | Template | on-demand | MTP device automount (activated by udev rules) |

## Common Operations

```bash
# Check all managed services
systemctl --user status claude-imports password-store-sync.timer mako-watcher.path tmux spotify-notify

# View all managed unit files
systemctl --user list-unit-files | grep -E '(claude|tmux|mako|password|mtp|spotify)'

# Enable a new service
systemctl --user enable --now <service-name>

# Reload after editing unit files
systemctl --user daemon-reload
```

## Service Dependencies

- **claude-imports**: Requires `inotifywait` (inotify-tools package)
- **mako-watcher**: Requires `makoctl` (mako package)
- **password-store-sync**: Requires `pass`, `git`, network access
- **tmux**: Requires tmux binary, starts before shell profile loads
- **spotify-notify**: Requires `playerctl`, `notify-send` (libnotify-bin)
- **mtp-automount**: Requires `gio`, udev rules in `/etc/udev/rules.d/`

## Notes

- `tmux.service` uses `enable` only (not `--now`) — it starts at login via systemd user session
- `mtp-automount@.service` is a template unit — instances are started by udev rules, not manually
- The `password-store-sync.timer` also triggers `dotfiles-sync` for multi-machine sync

## Cross-References

- **Sync system**: `SYNC_WORKFLOW.md`, `SYNC_DEPLOYMENT.md`
- **MTP setup**: `system/CLAUDE.md` (udev rules, device configuration)
- **Top-level overview**: `../CLAUDE.md`
