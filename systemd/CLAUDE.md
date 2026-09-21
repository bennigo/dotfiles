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

**Startup target — `default.target`, not `graphical-session.target`.**

Originally written as `WantedBy=graphical-session.target` to keep the restore out of login. That
does **not work on this machine**: there is no user-session systemd target. sway is launched by
`/usr/local/bin/sway-debug` (which is only `exec sway --unsupported-gpu`), nothing runs
`systemctl --user start graphical-session.target`, and the target is therefore permanently
`inactive`. Confirmed 2026-09-21:

```text
graphical-session.target      active=inactive  enabled=static
mako-watcher.path             active=inactive          <- never ran, same root cause
sway-session.target           active=inactive  enabled=not-found
```

Anything `WantedBy=graphical-session.target` silently never starts — which is why `herdr.service`
did not autostart on the first test, and why `mako-watcher.path` has never worked. Using
`default.target` makes it a sibling of `claude-imports.service` / `tmux.service`, which do start.

At login is cheap enough here because `resume_agents_on_restore=false` means a restore brings back
only shells in their cwds, not 11 agents each starting an MCP roster.

**If you do want true "after the desktop"**, fix the root cause rather than this unit — add to
`sway/.config/sway/config` (near the other startup `exec` lines):

```text
exec --no-startup-id systemctl --user start graphical-session.target
```

That activates the target, pulls in everything wanted by it (herdr *and* mako-watcher.path), and
restores the intended `After=`/`PartOf=` semantics. Not applied yet — it is a wider behavioural
change than the herdr fix, so it was left as a deliberate follow-up.

Note the service **must** run through a login shell (`/bin/zsh -lc`) — see the comment in the
unit: `systemctl --user` has a bare `PATH` and no API keys, and `~/.zshenv` is what supplies both.

> ⚠ **Stow + systemd hazard.** `systemctl --user disable <unit>` deletes the **stow symlink** in
> `~/.config/systemd/user/`, not just the `.wants/` link — after which the unit reports
> `not-found` and `enable` fails with *"Unit … does not exist"*. Always **stow first, then
> enable**, and after any `disable` re-run `stow -R --no-folding systemd` before re-enabling.
> Hit for real on 2026-09-21 while moving this unit from `graphical-session.target` to
> `default.target`.
>
> The 18:51 verification above was recorded with auto-resume **on** (herdr's default). See
> `[session] resume_agents_on_restore` below for turning that off.

### `[session] resume_agents_on_restore` — don't auto-reopen conversations

By default a restore does not merely re-create panes: it **re-launches each agent with its
recorded conversation**. A reboot therefore silently reopens all 11 agents (and every MCP roster
they start) whether or not you wanted to return to that work.

Set in `herdr/config.toml`:

```toml
[session]
resume_agents_on_restore = false
```

Agent panes then come back as **plain shells in the correct cwd**. herdr still records the
session identity, so the conversation stays reachable on demand.

Verification notes (this key appears in no offline doc — it was found in the herdr binary and
confirmed against the schema):
```bash
herdr config check                  # validates config.toml; reports "config: ok"
herdr server reload-config          # applies to a RUNNING server, no restart needed
```
- The table is **`[session]`**, and it accepts exactly `resume_agents_on_restore`. Sibling-looking
  names such as `default_shell` and `scrollback_limit_bytes` are rejected there
  (`unknown config key session.…`), so do not assume other `[session]` keys exist.
- It is a **boolean** — a string value is a TOML parse error, not a silent coercion.
- It affects the *next* restore, never the current session, so `reload-config` is safe.

### `herdr-resume-hints` — the recovery commands

With auto-resume off you need to know *what* to reopen. `local_bin/.local/bin/herdr-resume-hints`
reads `~/.config/herdr/session.json` and prints a ready-to-run command per agent pane:

```bash
herdr-resume-hints              # grouped listing (workspace, tab, cwd)
herdr-resume-hints --commands   # bare `cd … && …` lines, pipeable
herdr-resume-hints --snapshot   # save to ~/.local/state/herdr/resume-hints.txt, then print
herdr-resume-hints --file PATH  # read a given session.json OR a rendered snapshot
```

Resume syntax is verified per tool: `claude --resume <uuid>` (herdr stores `kind=id`) and
`pi --session <transcript-path>` (herdr stores `kind=path`). Unknown agent/kind pairs are printed
as a bracketed note rather than a command that would fail.

**Why `--snapshot` exists.** `agent_session` records are only guaranteed to exist while the agents
are running — herdr owns that file and may rewrite it on restore. A snapshot taken *before*
shutdown survives, so the commands are still available afterwards. To automate it, add an
`ExecStop` ahead of the server stop:

```ini
ExecStop=%h/.local/bin/herdr-resume-hints --snapshot
ExecStop=%h/.local/bin/herdr server stop
```

(Multiple `ExecStop=` lines run in order, so the snapshot is taken while the session is still
intact.)

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
