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
| `tmux.service` | Forking | — | **RETIRED on laptops 2026-09-23.** The unit file stays in the repo for the `agent_server` profile (headless agent hosting) but is no longer deployed or enabled here — its `Type=forking` start had been timing out for ~3 weeks, producing the 0-byte resurrect saves described below |
| `herdr.service` | Simple | `enable` only | Starts the herdr server with the graphical session — restores all saved workspaces/tabs/panes **as plain shells** (`[session] resume_agents_on_restore=false`); agents are reopened on demand — each restored pane prints its own command on startup (`herdr-pane-resume-hint`), or list every one with `herdr-resume-hints`. See "herdr persistence" below |
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

**Startup target — `graphical-session.target`, pulled in by `sway-session.target`.**

herdr is a *session* service: its panes are the user's terminals, so it has to inherit the
graphical session environment (WAYLAND_DISPLAY, SWAYSOCK, the session PATH). It is therefore
`WantedBy=graphical-session.target` with `After=`/`PartOf=graphical-session.target`.

That only works because `sway-session.target` now exists, because `graphical-session.target`
ships with `RefuseManualStart=yes` and therefore **cannot be started directly**:

```text
$ systemctl --user start graphical-session.target
Failed to start graphical-session.target: Operation refused, unit graphical-session.target
may be requested by dependency only (it is configured to refuse manual start/stop).
```

A `BindsTo=` edge *is* a dependency, so a unit that binds to it pulls it in. That is the
documented idiom — systemd's own `gnome-session.target` does exactly this, with the comment
"gnome-session.target pulls in graphical-session.target":

```ini
# systemd/.config/systemd/user/sway-session.target
[Unit]
BindsTo=graphical-session.target
Before=graphical-session.target
```

sway starts it, importing the session environment into the systemd user manager *first*. The two
commands are sequenced in **one** shell on purpose — two `exec` lines would race, and the target
could activate before the env landed, leaving herdr (and its panes) without it:

```text
# sway/.config/sway/config
exec --no-startup-id sh -c 'dbus-update-activation-environment --systemd WAYLAND_DISPLAY SWAYSOCK XDG_SESSION_TYPE XDG_CURRENT_DESKTOP; systemctl --user start sway-session.target'
```

Verified live 2026-09-22: starting `sway-session.target` made `graphical-session.target` active
and started `mako-watcher.path` — **the first time it had ever run** — while leaving the running
herdr untouched. `After=`/`PartOf=` are non-inert now (they were meaningless while the target
could never activate).

> **Vendor-enabled duplicates — mask `waybar.service` + `mako.service`.** Activating the target
> also woke two units that the waybar/mako packages enable by default under
> `/etc/systemd/user/graphical-session.target.wants/`. This machine does NOT use them: sway owns
> both bars via `bar` blocks (`swaybar_command` = `launch-top.sh` / `launch-herdr.sh`), and mako
> is D-Bus-activated (its cgroup is `dbus.service`, not `mako.service`). Leaving them enabled
> produced a third waybar and a spurious `mako.service` failure (*"Is a notification daemon
> already running?"*). Fix (user-level mask, no root needed):
>
> ```bash
> systemctl --user mask waybar.service mako.service
> systemctl --user stop  waybar.service
> ```
> The remaining `/etc/systemd/user/graphical-session.target.wants/` entries (`foot-server.service`,
> `spice-vdagent.service`, the update-notifier `*.path` units) are harmless and correct to keep.

> **Three wrong answers, do not repeat them.** (1) The unit was originally on
> `WantedBy=graphical-session.target` with nothing able to activate that target, so herdr
> silently never autostarted. (2) The follow-up "fix" was to have sway run
> `systemctl --user start graphical-session.target` directly — refused outright, per the error
> above. (3) A stop-gap parked the unit on `default.target`, which *did* start herdr but handed
> it a bare systemd environment: no `WAYLAND_DISPLAY`, no `SWAYSOCK`, and a PATH without the tool
> directories the zsh configs add. That is what broke `ctrl+a o` — `herdr-sessionx` could not
> find `fzf`, exited 0 in ~40 ms, and the picker popup merely flashed and vanished. See
> `zsh/.zshenv` (fzf for non-interactive consumers) and `local_bin/.local/bin/herdr-sessionx`
> (resolves fzf itself, and now fails loudly instead of silently).

Anything `WantedBy=graphical-session.target` starts only when `sway-session.target` is started,
i.e. from sway's config — never at login. If a session unit mysteriously never runs, check
`systemctl --user is-active graphical-session.target` first.

Note the service **must** run through a login shell (`/bin/zsh -lc`) — see the comment in the
unit: `systemctl --user` has a bare `PATH` and no API keys, and `~/.zshenv` is what supplies both.

> ⚠ **Stow + systemd hazard.** `systemctl --user disable <unit>` deletes the **stow symlink** in
> `~/.config/systemd/user/`, not just the `.wants/` link — after which the unit reports
> `not-found` and `enable` fails with *"Unit … does not exist"*. Always **stow first, then
> enable**, and after any `disable` re-run `stow -R --no-folding systemd` before re-enabling.
> Hit for real on 2026-09-21 while moving this unit between targets.
>
> To move a unit between systemd targets: edit `[Install]`, re-stow, `rm` the stale symlink in
> `~/.config/systemd/user/<old-target>.wants/`, create the new one by hand
> (`ln -s /home/bgo/.dotfiles/systemd/.config/systemd/user/<unit>
> ~/.config/systemd/user/<new-target>.wants/<unit>` — that absolute form is what `enable`
> produces and what the existing links use), then `systemctl --user daemon-reload`. Avoid
> `disable` entirely on stow-managed units.
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

### `herdr-pane-resume-hint` — the command, printed *inside the pane it belongs to*

`herdr-resume-hints` answers *"what was open?"* centrally. This answers *"what was THIS shell?"*
from inside the pane — the question you actually have when eleven restored shells are staring at
you and you cannot tell which was the receivers work and which was the vault.

Wired automatically: `zsh/.config/zsh/herdr-resume-hint.zsh`, sourced at the end of
`zsh/.config/zsh/.zshrc`, calls it on every interactive shell start. A restored pane therefore
prints this before you type anything:

```text
⏯  wF:p1 (wF) · 2. pi · /home/bgo/.dotfiles
   this pane held this conversation
   pi --session /home/bgo/.local/share/pi/sessions/2026-09-23T19-02-26-947Z_…jsonl   just now
```

**Two sources, in order of trust** — this is the whole design:

1. **The pane's own `agent_session` record**, read from `herdr pane current` (falling back to
   `herdr pane get $HERDR_PANE_ID`). Exact, and survives a restore.
2. **The newest pi/claude session whose project is this pane's cwd** — for panes that never ran an
   agent or whose record was lost. pi is indexed from the `cwd` field in each transcript header;
   claude is resolved via `~/.claude/projects/<encoded-cwd>/sessions-index.json`. Whichever of the
   two was touched most recently wins, and the line is labelled as inferred rather than presented
   as a fact about the pane.

```bash
herdr-pane-resume-hint                 # this pane (once per boot)
herdr-pane-resume-hint --force         # print again, ignoring the marker
herdr-pane-resume-hint --all           # every pane with a recorded conversation
herdr-pane-resume-hint --commands      # bare `cd … && …` lines, pipeable
herdr-pane-resume-hint --pane wF:p1    # inspect another pane
herdr-pane-resume-hint --cwd DIR       # answer for a directory, ignoring this pane
```

**Three properties worth not breaking:**

- **It can never print another pane's conversation.** `herdr pane current` resolves via the
  calling process's terminal, so if its answer disagrees with `$HERDR_PANE_ID` the script re-asks
  by id.
- **It is a no-op outside herdr**, gated on `$HERDR_ENV` before any socket call, so the `tmux` /
  plain-kitty case is untouched. Inside a pane with nothing to resume it stays silent too.
- **Once per boot per pane**, via a marker in `~/.local/state/herdr/hint-shown/` keyed on
  `/proc/sys/kernel/random/boot_id` — so it appears after a reboot but not on every nested
  subshell. Any explicit flag bypasses the marker.

### Dead ends: `⚠ empty` and `⚠ transcript missing`

herdr records a session identity even when there is nothing behind it. Two kinds were found in
this session's live state:

| Case | Example | Detection |
|---|---|---|
| **empty** — never produced an assistant turn | `wF:p46` → claude `aa8faf6e`, a `/exit` stub (3.3 KB, 0 assistant records) | no `"type":"assistant"` (claude) / no `"role":"assistant"` (pi) in the transcript |
| **missing** — the transcript is gone | `w12:p2` → pi `2026-09-13T12-00-20…jsonl`, deleted since | recorded path does not exist |

Both are shown with a `⚠` line and, when the cwd has a real conversation, a `↳ use instead:`
line pointing at it. `--commands` skips the dead one outright and leaves a `#` comment, so piping
into `bash` cannot reanimate a stub.

**The test is the transcript, not `sessions-index.json`.** The index proved unreliable — for
`aa8faf6e` it had no entry at all, so `messageCount` was simply unavailable. The transcript is
ground truth.

> A missing transcript is also why `human_age` now refuses non-numeric input. It used to fall
> through to `ref="$1"` and do `$(( epoch - ref ))` on a *path*, aborting with
> `arithmetic syntax error`. Found via `w12:p2` in an `--all` sweep.

### One conversation, one pane

Two panes attached to the same transcript both write to it, so a conversation that is already
held by another pane is **reported**, not offered a second time:

```text
⏯  wE:p1 (wE) · 1. bgo rek_d01 · /home/bgo/work/gps_servers
   no conversation recorded for this pane — newest session in this directory
   claude --resume e6018791-08ed-44df-9633-ac30fe754ada   12 h ago
   ↳ already open in wE:p9 — resuming it here would open one transcript twice
```

This matters most for the `--cwd` fallback, which by construction points at "the newest session in
this directory" — a conversation another pane may well be holding. `--commands` emits a `#`
comment instead of the command. A per-pane view cannot see this on its own, so `--all` also audits
for a session claimed by two panes and reports it on stderr.

**Cost and the jq trap.** The banner path is ~50 ms: jq process startup (~25 ms) dominates, so the
pane object and its `agent_session` are each parsed **exactly once** into tab-separated fields.
Per-field jq calls had pushed this to 148 ms — do not reintroduce them. The repeat-shell path is
free (0.00 s) because the dedupe marker is keyed on `$HERDR_PANE_ID`, which lets a second shell in
the same pane exit before the socket round-trip. The pi index (`~/.local/state/herdr/pi-index.tsv`)
is rebuilt only when the session directory gains a file, because reading all ~145 transcript
headers costs ~0.3 s — too much for every shell start, and panes carrying their own record never
touch it. `--all` is ~0.7 s for 13 panes; it is an audit command, not a startup path.

> Note that `claude_project_dir` must encode **every** non-alphanumeric character as `-`, not just
> `/` and `.`: `/home/bgo/work/gps_servers` is `-home-bgo-work-gps-servers`. Getting this wrong
> does not produce a wrong answer (the `projectPath` scan still finds it) but silently turns the
> fast path into a scan of every project index.
>
> The pane record is only as fresh as herdr's own tracking: a pane whose agent was restarted
> reports whatever that agent last reported. `herdr pane get <id>` is the ground truth — the tool
> prints exactly what it says, and never guesses.

## Common Operations

```bash
# Check all managed services
systemctl --user status claude-imports password-store-sync.timer mako-watcher.path herdr spotify-notify

# View all managed unit files
systemctl --user list-unit-files | grep -E '(claude|herdr|mako|password|mtp|spotify)'

# Enable a new service
systemctl --user enable --now <service-name>

# Reload after editing unit files
systemctl --user daemon-reload
```

## Service Dependencies

- **claude-imports**: Requires `inotifywait` (inotify-tools package)
- **mako-watcher**: Requires `makoctl` (mako package)
- **password-store-sync**: Requires `pass`, `git`, network access
- **herdr**: Requires the herdr binary and a graphical session (`WantedBy=graphical-session.target`)
- ~~**tmux**: Requires tmux binary, starts before shell profile loads~~ — retired on laptops; see the note below
- **spotify-notify**: Requires `playerctl`, `notify-send` (libnotify-bin)
- **mtp-automount**: Requires `gio`, udev rules in `/etc/udev/rules.d/`

## Notes

- `herdr.service` uses `enable` only (not `--now`) — it starts with the graphical session
- **tmux is retired on laptops (2026-09-23).** Its unit is no longer deployed here; the file is kept
  only for the `agent_server` profile. The Ansible dotfiles role now also rejects `tmux` during
  stow auto-discovery, so a bootstrap will not bring the config back; `agent_server.yml` lists it
  explicitly. See "herdr persistence" below for what replaced it (including the resume hints).
- `mtp-automount@.service` is a template unit — instances are started by udev rules, not manually
- The `password-store-sync.timer` also triggers `dotfiles-sync` for multi-machine sync

## Cross-References

- **Sync system**: `SYNC_WORKFLOW.md`, `SYNC_DEPLOYMENT.md`
- **MTP setup**: `system/CLAUDE.md` (udev rules, device configuration)
- **Top-level overview**: `../CLAUDE.md`

---

*Last reviewed: 2026-04-11*
