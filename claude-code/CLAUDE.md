# Claude Code Configuration

Configuration for Claude Code CLI tool, MCP servers, notification hooks, and remote control.

## MCP Servers (`.mcp.json`)

Deployed via stow to `~/.mcp.json` (user scope — must be at `~/`, not `~/.config/`).

### Web & Search
- **fetch**: Web content fetching (via uvx/mcp-server-fetch)
- **brave-search**: Web search via Brave Search API

### PostgreSQL Database Access

Via `postgres-mcp` (PyPI, run with `uvx`). Uses `DATABASE_URI` env var and `--access-mode` flag.
Multiple connections configured for various projects:

| Server | Database | Access |
|--------|----------|--------|
| `postgres-local` | Local development | Read-write |
| `postgres-gas-readonly` | Production GAS | Read-only |
| `postgres-skjalftalisa-readonly` | Production earthquake | Read-only |
| `postgres-tos-readonly` | Production TOS | Read-only |
| `postgres-epos-readonly` | Development EPOS | Read-only |
| `postgres-gnss-readonly` | Development GNSS | Read-only |
| `postgres-metrics-readonly` | Development metrics | Read-only |

### Google Workspace (`google-workspace`)

Multi-account Google Workspace access via [`@aaronsb/google-workspace-mcp`](https://github.com/aaronsb/google-workspace-mcp).

**Authenticated accounts:**

| Account | Category | Description |
|---------|----------|-------------|
| `bgovedur@gmail.com` | personal | Personal Gmail |
| `benedikt@klifursamband.is` | work | KI Climbing Association |

**Services:** Gmail, Calendar, Drive, Sheets, Docs, Tasks, Meet

**Tools:** `manage_email`, `manage_calendar`, `manage_drive`, `manage_sheets`, `manage_docs`,
`manage_tasks`, `manage_meet`, `manage_accounts`, `manage_workspace`, `manage_scratchpad`, `queue_operations`

Each tool takes an `email` parameter to specify which account to use.

**Credentials:** OAuth via GCP project "Claude code" (bgovedur org). Tokens stored
XDG-compliant at `~/.config/google-workspace-mcp/accounts.json` and
`~/.local/share/google-workspace-mcp/credentials/`.

**Account routing policy:** See `../CLAUDE.md` → "Google Account Routing Policy"

**Re-authenticating accounts:**
```bash
bash /tmp/auth-google.sh  # Edit script to change email, then run
```

### Environment Variables

MCP servers require connection strings set in shell profile (`zsh/.config/zsh/exports.zsh`):

```bash
BRAVE_API_KEY              # Brave Search API
GOOGLE_MCP_CLIENT_ID       # Google OAuth client ID (from pass)
GOOGLE_MCP_CLIENT_SECRET   # Google OAuth client secret (from pass)
LOCAL_POSTGRES_URL         # postgresql://user:pass@localhost:5432/dbname
PROD_GAS_URL               # Production GAS database
PROD_SKJALFTALISA_URL      # Production earthquake database
PROD_TOS_URL               # Production TOS database
DEV_EPOS_URL               # Development EPOS database
DEV_GNSS_URL               # Development GNSS database
DEV_METRICS_URL            # Development metrics database
```

**Security**: Config uses `${VAR}` references — no credentials stored in this repository.
Production databases are read-only for safety. Google OAuth tokens managed by the MCP server locally.

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

## Remote Control

Claude Code can be accessed from phone or browser via remote control.

### Tmux Integration
Persistent `claude-rc` window spawned at tmux startup:
- Uses full path to npm-global claude binary (avoids PATH issues when tmux starts via systemd)
- Only creates window if it doesn't exist (safe to re-source tmux.conf)
- See `tmux/.config/tmux/CLAUDE.md` for details

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
- **Tmux remote control**: `tmux/.config/tmux/CLAUDE.md`
- **Database setup**: `ansible/DATABASE_SETUP.md`
- **Top-level overview**: `../CLAUDE.md`
