# Waybar Configuration

Status bar for Sway with custom modules, git sync monitoring, and system indicators.

## Layout

```
Left:    App menu │ Workspaces │ Window title
Center:  Screen recording │ Sway mode
Right:   Weather │ Sunset │ Music │ Clipboard │ Git Sync │ CPU/Mem/Battery │ Network │ Audio │ Clock │ Power │ Tray
```

- **Position**: Top, height 20px
- **Layer**: Bottom (windows can cover it)

## Key Modules

### Git Sync Status (custom module)
Monitors three repositories: dotfiles, claude-private, password-store.

**Display format**: `P:✓ C:✓ D:↑` (Password Store, Claude, Dotfiles)

| Indicator | Meaning | Style |
|-----------|---------|-------|
| `✓` | Synced | Green |
| `↑` | Commits ahead (push needed) | Yellow pulsing |
| `↓` | Commits behind (pull needed) | Yellow pulsing |
| `⚠` | Uncommitted changes | Yellow pulsing |
| `✗` | Error | Red |

**Interactions**: Left-click runs `dotfiles-sync`, right-click shows detailed status.
Updates every 60 seconds.

**Setup**: See `SETUP_GIT_SYNC.md` for installation and configuration.

### Clipboard (`cliphist`)
- Left-click: Open clipboard history picker
- Right-click: Delete entry
- Middle-click: Clear all

## Custom Scripts (`scripts/`)

| Script | Purpose |
|--------|---------|
| `git-sync-status` | Multi-repo git status monitor (main module script) |
| `git-sync-status-window` | Window version of git sync display |
| `git-sync-run` | Runs sync in floating kitty terminal |
| `setup-git-sync-module` | Automated setup for the git-sync module |
| `weather.py` | Weather information module |
| `network-menu.sh` | Network management rofi menu |
| `sunset.sh` | Sunset/sunrise time display |
| `blueman-manager-toggle.sh` | Bluetooth manager toggle |

## Configuration Files

- `config.jsonc` — Main module configuration (JSON with comments)
- `style.css` — Visual styling
- `modules/git-sync.json` — Git sync module definition

## Cross-References

- **Sync system**: `SYNC_WORKFLOW.md`, `local_bin/CLAUDE.md` (dotfiles-sync)
- **Sway integration**: `sway/.config/sway/CLAUDE.md`
- **Top-level overview**: `../CLAUDE.md`
