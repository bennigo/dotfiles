# dotfiles

GNU Stow deployment of all configuration modules. Discovers stow directories, deploys
symlinks, enables systemd user services, configures shell environment integration
(zsh, cargo, fnm, fzf).

## When to run

After all other roles — this is the final integration step that activates all configs.

```bash
ansible-playbook bootstrap.yml --tags dotfiles
```

## What it does

- Stows all directories listed in `stow_directories` (or auto-discovers from repo)
- Deploys `systemd/` with `--no-folding` flag
- Deploys `zsh/` with `--ignore=.zshenv` workaround
- Enables systemd user services (claude-imports, mako-watcher, password-store-sync, tmux)
- Deploys `~/.local/bin/` scripts
- Configures shell integrations (cargo, fnm, fzf paths in `.zshrc`)

## Dependencies

- `base` (minimum)
- All other roles should run first for their configs to be available

## Key variables

- `stow_directories` — list of dirs to stow (empty = auto-discover)
- `dotfiles_systemd_services` — services to enable + start
- `dotfiles_systemd_services_no_start` — services to enable only (e.g., tmux)
- `dotfiles_verify_configs` — config dirs to verify after stow

## Verification

```bash
ls -la ~/.config/sway         # symlink to dotfiles?
systemctl --user status tmux  # service enabled?
which sway-shortcuts.sh       # scripts in PATH?
```

## See also

- [`../../STOW_ORDER.md`](../../STOW_ORDER.md) — deployment order and conflicts
- [`../../CLAUDE.md`](../../CLAUDE.md) — per-module documentation routing
