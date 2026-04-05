# Tmux Configuration

Terminal multiplexer setup with session persistence, plugin ecosystem, and Wayland integration.

## Overview

- **Prefix**: `C-a` (rebound from default `C-b`)
- **Theme**: Catppuccin (omerxx fork with meetings module)
- **Plugin manager**: TPM (Tmux Plugin Manager) at `~/.local/share/tmux/plugins/tpm/`
- **Session persistence**: tmux-resurrect + tmux-continuum (auto-save every 60s, auto-restore on boot)
- **Status bar**: Top position, Catppuccin theme with directory, date/time, battery, continuum modules

## Plugin Ecosystem (13 plugins)

| Plugin | Purpose |
|--------|---------|
| `tpm` | Plugin manager |
| `tmux-sensible` | Sensible defaults |
| `tmux-yank` | Clipboard integration |
| `tmux-resurrect` | Session save/restore (captures pane contents, nvim session strategy) |
| `tmux-continuum` | Automatic save/restore (60s interval, boot restore) |
| `tmux-thumbs` | Quick text selection/copy |
| `tmux-fzf` | Fuzzy finder integration |
| `tmux-fzf-url` | URL extraction and opening |
| `catppuccin-tmux` | Theme (omerxx fork) |
| `tmux-sessionx` | Advanced session management (zoxide, fzf-marks, tmuxinator) |
| `tmux-floax` | Floating pane support (`prefix + p` toggle, `prefix + P` menu) |
| `tmux-battery` | Battery status in status bar |

## Key Bindings

- `prefix + R` — Reload tmux config (`~/.config/tmux/tmux.conf`)
- `prefix + r` — Rename window
- `prefix + p` — Toggle floating pane (floax)
- `prefix + P` — Floating pane menu
- `prefix + o` — Session picker (sessionx with zoxide integration)
- `prefix + E` — Bulk refresh Wayland env vars in all panes (see below)

## Wayland Environment Fix

After reboot, `tmux-continuum` restores sessions before Sway starts, leaving `WAYLAND_DISPLAY`,
`SWAYSOCK`, and `DISPLAY` empty in restored panes. Two mechanisms fix this:

### Auto-refresh (per-shell)
`zsh/exports.zsh` defines `refresh-wayland-env` which pulls current values from the tmux
session env (populated by `update-environment` on attach). Runs automatically on shell
startup when `WAYLAND_DISPLAY` is empty inside tmux.

### Bulk refresh (all panes)
`prefix + E` sends `refresh-wayland-env` + Enter to every pane across all sessions —
useful for long-running shells that never re-sourced.

### How it works
The `update-environment` setting in tmux.conf ensures the session env gets fresh values on attach:
```
set -g update-environment "WAYLAND_DISPLAY XDG_RUNTIME_DIR DISPLAY SWAYSOCK PATH"
```

```bash
# Manual refresh in a single pane
refresh-wayland-env

# Verify
echo $WAYLAND_DISPLAY  # Should show wayland-1
```

## Claude Code Remote Control

A persistent `claude-rc` window is spawned at tmux startup for phone/browser access:

```
if-shell '! tmux list-windows -F "#W" | grep -q "^claude-rc$"' {
  new-window -d -n "claude-rc" "/home/bgo/.local/share/npm-global/bin/claude remote-control ..."
}
```

- Uses full path to npm-global claude binary to avoid PATH issues (tmux starts via systemd before shell profile)
- Only creates the window if it doesn't already exist (safe to re-source tmux.conf)
- Neovim also has `<leader>acR` keymap for launching remote control

## Session Management

- **SessionX**: `prefix + o` opens session picker with zoxide integration, fzf-marks, and tmuxinator support
- **Resurrect**: Saves/restores pane layout, working directories, and Neovim sessions
- **Continuum**: Auto-saves every 60s, auto-restores on tmux server start
- **Resurrect guard**: `scripts/resurrect-guard.sh` runs as pre-restore hook for safety checks

## Configuration Files

- `tmux.conf` — Main configuration (this directory)
- `tmux.reset.conf` — Key binding reset (sourced first)
- `scripts/` — Helper scripts (resurrect-guard, calendar)

## Terminal & Color Support

- **default-terminal**: `tmux-256color` (switched from `screen-256color` — required for strikethrough and other modern terminal features)
- **True color**: Enabled via `terminal-overrides` for kitty, tmux-256color, and foot terminals
- **Undercurl/underline styles**: `Smulx` and `Setulc` overrides for Neovim diagnostics
- **Strikethrough**: `smxx=\E[9m:rmxx=\E[29m` override + `terminal-features` with `strikethrough` flag — required for Neovim's `@markup.strikethrough` to render inside tmux
- **Clipboard/RGB**: `terminal-features '*:clipboard:strikethrough:usstyle:RGB'`

**Note**: Terminal type changes (`default-terminal`) require `tmux kill-server` and restart — config reload alone is insufficient.

## Cross-References

- **Wayland env function**: `zsh/.config/zsh/exports.zsh` (`refresh-wayland-env`)
- **Systemd tmux service**: `systemd/CLAUDE.md` (`tmux.service`)
- **Claude Code remote control**: `claude-code/CLAUDE.md`
- **Top-level overview**: `../../CLAUDE.md`
