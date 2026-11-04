# Waybar Configuration

Status bars for Sway: a top bar on every screen, a hidden herdr status bar, and a
mini pill shown while the top bar is hidden.

## Bars

Sway's `bar {}` blocks (`sway/.config/sway/config`) start two **supervisor scripts**,
not waybar directly:

| Supervisor | waybar config | Purpose |
|------------|---------------|---------|
| `launch-top.sh` | `config-top.jsonc` + `style-top.css` | Top bar (workspaces, metrics, clock, power) |
| `launch-herdr.sh` | `config-herdr.jsonc` + `style-herdr.css` | herdr status, `start_hidden`, overlay (`exclusive: false`) |
| (from `launch-top.sh`) | `config-mini.jsonc` + `style-mini.css` | 150px pill shown only while the top bar is hidden |

Toggles: `herdr-bars-toggle top` (Win+Shift+q), `herdr-bars-toggle herdr` (Win+Ctrl+q).
SIGUSR1 is a visibility **toggle** — never send it repeatedly.

### Top bar: two bars, one process

`config-top.jsonc` is an **array** of two bars sharing `top-modules.jsonc` via
`"include"` (keys in the bar object win over included ones):

- `"output": "!DP-2"` — full bar: all workspaces + 17 right modules (~1900px of content)
- `"output": "DP-2"` — short bar for the **portrait** Dell (1080px wide): own
  workspaces only (`all-outputs: false`), volume, clock, language, power

A layer-shell bar can't shrink below its content, so the full bar on a portrait
screen spills onto the neighbouring output. DP-2 is the portrait screen in the
kanshi `work`/`work-dup` profiles (`kanshi/.config/kanshi/config`). Add new modules to
`top-modules.jsonc`, then list them in the bar(s) that should show them.

## Supervisors (`launch-*.sh`)

Every 5s: if the bar's waybar is gone, restart it (retrying past the layer-shell race
during `swaymsg reload`). Gotchas:

- **`WAYLAND_SOCKET`**: sway starts `swaybar_command` with a one-shot Wayland socket fd.
  The first waybar consumes it; later restarts inheriting it die with
  "Bar need to run under Wayland". The scripts `unset WAYLAND_SOCKET` after the first launch.
- **Single instance**: each script kills older processes matching `pgrep -f "$0"` —
  including any shell whose command line contains the script path. Start a fresh
  supervisor from a terminal with `setsid -f`, not from a shell you need to keep.
- Restart the top bar without `swaymsg reload` (which undoes the kanshi layout):
  `pkill -f '[w]aybar -c .*config-top'` — the supervisor brings it back within ~5s.
- Startup logs: `/tmp/waybar-top.*.log` / `/tmp/waybar-herdr.*.log` (deleted on success).

## Key Modules

Most top-bar modules are `custom/*` backed by `~/.local/bin/herdr-waybar-*` scripts
(`metrics`, `io`, `gitsync`, `recording`, `lang`) — see `local_bin/CLAUDE.md`.
Signals (`pkill -RTMIN+N waybar`) refresh a module immediately; numbers are in
`top-modules.jsonc`.

### Git Sync Status
`custom/git-sync` (`herdr-waybar-gitsync`) shows dotfiles / claude-private /
password-store sync state. Left-click runs the sync (`scripts/git-sync-run`),
right-click shows `dotfiles-sync --status`. Setup history: `SETUP_GIT_SYNC.md`.

## Custom Scripts (`scripts/`)

| Script | Purpose |
|--------|---------|
| `git-sync-status` | Multi-repo git status monitor (legacy module script) |
| `git-sync-status-window` | Window version of git sync display |
| `git-sync-run` | Runs sync in floating kitty terminal |
| `setup-git-sync-module` | Automated setup for the git-sync module |
| `weather.py` | Weather information module |
| `network-menu.sh` | Network management rofi menu |
| `sunset.sh` | Sunset/sunrise time display |
| `blueman-manager-toggle.sh` | Bluetooth manager toggle |

## Other Files

- `config.jsonc` / `style.css` — older single-bar config, not started by sway
- `modules/` — legacy module definitions

## Cross-References

- **Output profiles (which screen is DP-2)**: `kanshi/.config/kanshi/config`
- **Sync system**: `SYNC_WORKFLOW.md`, `local_bin/CLAUDE.md` (dotfiles-sync)
- **Sway integration**: `sway/.config/sway/CLAUDE.md`
- **Top-level overview**: `../CLAUDE.md`

---

*Last reviewed: 2026-11-04*
