# Claude Code Configuration

Configuration for Claude Code CLI tool, MCP servers, notification hooks, and remote control.

## MCP Servers — DISABLED (2026-09-20)

**Active config is empty.** `.mcp.json` now contains `{"mcpServers": {}}` and the previous
11-server definitions are preserved in **`.mcp.json.disabled`** for easy restore:

```bash
# re-enable everything
mv claude-code/.mcp.json.disabled claude-code/.mcp.json
# or restore just one server by copying its block back into the active file
```

### Why they were removed

Measured over **82 Claude Code transcripts spanning a full year** (2025-09-25 → 2026-09-20),
counting real `tool_use` blocks:

| MCP server | invocations in a year |
|---|---:|
| `claude-in-chrome` (cloud connector, spawns nothing local) | 362 |
| `brave-search` | 4 |
| `gps-health-pgdev` | 2 |
| `firecrawl` | 2 |
| `fetch` | 2 |
| `postgres-*` (all 7), `google-workspace`, `excalidraw` | **0** |

For scale, in the same window: `Bash` 20,642, `Edit` 2,318, `Read` 1,296.

These servers were spawned by **every** session regardless of use (~12 processes per session),
and with 6-7 concurrent claude agents that is ~75-84 processes. This was the dominant term in
the **41.7 GB of `node` memory** present during the 2026-09-20 hard freeze — see
`system/CLAUDE.md` → "Memory Pressure Guards".

Everything they provided is available natively in pi, which is where the work actually happens
(319 pi transcripts: `web_search` 660, `web_fetch` 358, `pg_query` 86 — versus **12** uses of
pi's `mcp` gateway in total):

| Removed MCP server | Native replacement |
|---|---|
| `fetch`, `brave-search`, `firecrawl` | pi `web_search` / `web_fetch` |
| `postgres-*` (7) | pi `pg_query`, `pg_list_databases`, `pg_describe_table` |
| `google-workspace` | pi Google tooling / claude.ai connectors |
| `excalidraw` | `excalidraw-canvas.service` + the excalidraw skill |

> **Note on firecrawl.** Firecrawl *may* still be active as a backend provider inside pi's
> native `web_search`/`web_fetch` — that would be configured in
> `~/.config/pi/agent/auth.json`, which this repo does not read. Removing the firecrawl **MCP
> server** does not affect that. If search results stop being firecrawl-quality, this is the
> first thing to check.

Also removed: `excalidraw`, which was defined separately in `~/.claude.json` (user scope) rather
than here. Removed with `claude mcp remove excalidraw -s user`; recover with
`claude mcp add`.

### Still active (deliberately NOT touched)

Project-scoped MCP servers defined in individual projects' own `.mcp.json` files, plus pi's own
MCP installs (`~/.config/pi/agent/mcp-cache.json`: `zotero`, `exa`, `semantic-scholar`,
`gps-health-pgdev`). These are work-critical and were out of scope for the trim: `mcp-grafana`,
`mcp-gdrive`, `mcp-gmail`, `gps-health-*`, `semanticscholar`, `zotero`.

### Reference — the archived server set

Kept for when a server needs restoring. **Format**: `{ "mcpServers": { ... } }` wrapper is
required — Claude Code reads `.mcp.json` via a project-scope tree walk (from CWD up to `/`) using
a schema that requires the `mcpServers` key. Flat format fails schema validation.

**Dependencies**: `postgres-mcp` via `uv tool install postgres-mcp`; `mcp-server-fetch` via uvx.

| Server | Purpose |
|--------|---------|
| `fetch` | Web content fetching (uvx `mcp-server-fetch`) |
| `brave-search` | Web search (`.scripts/brave-mcp-wrapper.sh`) |
| `firecrawl` | Scrape/crawl (`npx firecrawl-mcp`) |
| `postgres-local` | Local development (read-write) |
| `postgres-gas-readonly` | Production GAS (read-only) |
| `postgres-skjalftalisa-readonly` | Production earthquake (read-only) |
| `postgres-tos-readonly` | Production TOS (read-only) |
| `postgres-epos-readonly` | Development EPOS (read-only) |
| `postgres-gnss-readonly` | Development GNSS (read-only) |
| `postgres-metrics-readonly` | Development metrics (read-only) |
| `google-workspace` | Multi-account Google Workspace (`@aaronsb/google-workspace-mcp`) |

`google-workspace` authenticated two accounts — `bgovedur@gmail.com` (personal) and
`benedikt@klifursamband.is` (KI) — exposing `manage_email`, `manage_calendar`, `manage_drive`,
`manage_sheets`, `manage_docs`, `manage_tasks`, `manage_meet`, `manage_accounts`,
`manage_workspace`, `manage_scratchpad`, `queue_operations`, each taking an `email` parameter.
OAuth tokens live XDG-compliant at `~/.config/google-workspace-mcp/accounts.json` and
`~/.local/share/google-workspace-mcp/credentials/`. Account routing policy is in `../CLAUDE.md`.

Required env vars (set in `zsh/.config/zsh/exports.zsh`) — `BRAVE_API_KEY`,
`GOOGLE_MCP_CLIENT_ID`, `GOOGLE_MCP_CLIENT_SECRET`, `LOCAL_POSTGRES_URL`, `PROD_GAS_URL`,
`PROD_SKJALFTALISA_URL`, `PROD_TOS_URL`, `DEV_EPOS_URL`, `DEV_GNSS_URL`, `DEV_METRICS_URL`.

**Security**: the config uses `${VAR}` references — no credentials are stored in this repository
(verified 2026-09-20: every env value is an env-var reference, not a literal). Production
databases are read-only for safety.

## Notification Hook

Claude Code notifications are forwarded to Mako (system notification daemon) via a hook
in `~/.claude/settings.json`. This is needed because inside Neovim's terminal buffer,
standard notification mechanisms (OSC sequences, terminal bells) are swallowed.

### Architecture
```
Claude Code hook (Notification event)
  → claude-notify script (local_bin/)
    → reads JSON on stdin
    → determines urgency (critical for permission prompts, normal for idle)
    → notify-send with -t flag
      → Mako via D-Bus
```

### Testing
```bash
echo '{"notification_type":"idle_prompt","message":"Test","title":"Claude Code"}' | claude-notify
```

### Important Notes
- Mako `[urgency=high]` has `default-timeout=0` (infinite) — always use `-t` flag in notify-send
- The hook runs as a separate process, reaching Mako directly via D-Bus (bypasses Neovim terminal)

## Skills (Shared with Pi)

Skills are stored in `~/.claude/skills/<name>/SKILL.md` — this is the **shared source of truth**
with Pi. Both agents auto-discover this directory; no config needed on the Claude Code side.

**40 skills available**: vault-health, jot, floorit, capture-to-vault, weave-links, transcribe,
voice-input, expand-stub, sort-inbox, connect-orphans, and 30 more.

**Runtime compatibility varies per skill.** 10 skills require Claude Code-specific tooling
(MCP servers, `TaskCreate`, `WebFetch`, `WebSearch`) and fail at runtime in Pi (which has
no MCP and no built-in WebSearch/WebFetch). These carry a `## Requirements` section in
their `SKILL.md`. The remaining 30 are pure-Bash and work in both agents.

Affected skills: `search-scholar`, `verify-claim`, `fetch-source`, `verify-damage`,
`current-events`, `research-brief`, `expand-topic`, `add-citations`, `evaluate-sources`,
`search-sources`.

**Creating new skills**: `mkdir ~/.claude/skills/<name>/` + `SKILL.md` with frontmatter:
```markdown
---
name: my-skill
description: What it does and when to use
---
```
Directory name must match `name:` field. Both Pi and Claude Code pick it up on next startup.

**Claude Code commands** (`~/.claude/commands/*.md`) still exist for `/command` invocation
and are Claude Code-only (Pi requires the skill format). Commands and skills can coexist
with the same name — no conflict.

**Cross-ref**: `pi/CLAUDE.md` for Pi-side skill configuration.

## Remote Control

Claude Code can be accessed from phone or browser via remote control.

### herdr Integration (was: tmux)
The persistent `claude-rc` tab is created on demand, not at startup:
- `prefix + alt+c` runs `local_bin/.local/bin/herdr-remote-control`, which focuses the existing
  `claude-rc` tab in the current workspace or creates it and types the command into its shell
- Uses the full path to the npm-global claude binary (the tmux original needed this because tmux
  started via systemd before any shell profile loaded; kept because it costs nothing and removes
  the failure mode)
- Never duplicates the tab — repeated presses focus the one that exists, matching the tmux
  binding's `if-shell 'select-window -t :claude-rc'` behaviour it replaced
- tmux is retired on laptops (2026-09-23): see `systemd/CLAUDE.md` → "herdr persistence"

### Neovim Integration
`<leader>acR` keymap launches a remote control session from within Neovim.

### Manual Launch
```bash
claude remote-control --name 'my-session'
```

## Deployment

```bash
cd ~/.dotfiles
stow claude-code    # Creates ~/.mcp.json symlink
```

Ansible bootstrap automatically deploys this with other dotfiles.

## Cross-References

- **Notification script**: `local_bin/.local/bin/claude-notify`
- **Shell env vars**: `zsh/.config/zsh/exports.zsh`
- **herdr remote control**: `local_bin/.local/bin/herdr-remote-control` (`prefix+alt+c`)
- **Database setup**: `ansible/DATABASE_SETUP.md`
- **Top-level overview**: `../CLAUDE.md`

---

*Last reviewed: 2026-04-11*
