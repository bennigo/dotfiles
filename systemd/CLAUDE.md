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
| `herdr.service` | Simple | `enable` only | Starts the herdr server with the graphical session — restores all saved workspaces/tabs/panes **and resumes the claude/pi agents in them** from `~/.config/herdr/session.json`. See "herdr persistence" below |
| `calendar-notify.timer` | Timer | `enable --now` | Checks Google Calendar events every 10 min, sends Mako notifications |
| `calendar-notify.service` | Triggered | via `.timer` | Runs calendar-notify script for both Google accounts |
| `spotify-notify.service` | Long-running | `enable --now` | Track change notifications via playerctl + notify-send |
| `mtp-automount@.service` | Template | on-demand | MTP device automount (activated by udev rules) |
| `backup-claude-sessions.timer` | Timer | `enable --now` | Nightly (03:00) restic backup of session transcripts to Google Drive |
| `backup-claude-sessions.service` | Triggered | via `.timer` | Runs `backup-claude-sessions` script (restic backup + retention) |
| `morning-prewarm.timer` | Timer | `enable --now` | Weekdays 07:30 — pre-warms daily note + market pulse before /morning-v2 |
| `morning-prewarm.service` | Triggered | via `.timer` | Runs `morning-prewarm` script (daily note + markets + Mako reminder) |

## herdr persistence (why rebooting is cheap)

herdr writes `~/.config/herdr/session.json` continuously (log events `persist.save`,
`outcome=ok`) and reads it back on startup (`persist.restore`, verified `workspaces=21`).
That file is **version 3** and contains, per workspace: `identity_cwd`, tabs, pane layout,
`focused`/`zoomed`, public pane/tab numbers, sidebar width and fold state.

Crucially, agent panes also carry an `agent_session` record — that is what makes a restore
*resume conversations* rather than just re-open a shell:

```json
"agent_session": { "source": "herdr:claude", "agent": "claude", "kind": "id",
                   "value": "edb9f04b-e581-4551-8495-3022fc9e1f49" }
"agent_session": { "source": "herdr:pi",     "agent": "pi",     "kind": "path",
                   "value": "/home/bgo/.local/share/pi/sessions/2026-09-20T19-02-43-668Z_…jsonl" }
```

- **claude** is tracked by session UUID. Those transcripts live in
  `~/.dotfiles/claude-private/.claude/projects/<encoded-cwd>/<uuid>.jsonl` and resume via
  `claude --resume <session-id>`.
- **pi** is tracked by transcript path (reported by
  `pi/.config/pi/agent/extensions/herdr-agent-state.ts`).

Verified after a real restore (2026-09-20 18:51): 45 panes respawned and all 11 agent panes
came back attached to their recorded sessions — the restored claude pane carried its original
conversation title ("✳ Receivers work: LTB run report and horizon semantics"), not a fresh
"Claude Code" banner.

**Cost of a restore:** it is eager, not lazy — all 21 workspaces' panes spawn at once
(34 shells, 7 claude, 4 pi). Because each claude agent starts its own full MCP roster, a
restore also spawns ~12 MCP processes per claude pane. This is the single biggest reason the
startup memory footprint is high, and why trimming the MCP roster in `claude-code/.mcp.json`
reduces both baseline RAM *and* the cost of every herdr restore. See
`system/CLAUDE.md` → "Memory Pressure Guards".

Check restore state without restarting:
```bash
herdr agent list        # live agents + their resumed agent_session values
herdr pane list         # every pane, with cwd and detected agent
grep -E 'persist.restore|persist.save' ~/.config/herdr/herdr-server.log | tail
```

**Startup target.** The unit is `WantedBy=graphical-session.target` (not `default.target` as
`tmux.service` uses) because a restore is eager — it pulls 45 shell/agent spawns plus 11 agents
and their MCP servers *before* you can use the desktop, which would contend with sway coming up.
Subscribe it with:
```bash
systemctl --user daemon-reload
systemctl --user enable herdr.service     # starts with the next graphical session
systemctl --user start  herdr.service     # or now
```
Note the service **must** run through a login shell (`/bin/zsh -lc`) — see the comment in the
unit: `systemctl --user` has a bare `PATH` and no API keys, and `~/.zshenv` is what supplies both.

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

---

*Last reviewed: 2026-04-11*
