# Claude Code Configuration

Configuration for Claude Code CLI tool, MCP servers, notification hooks, and remote control.

## MCP Servers (`.mcp.json`)

Deployed via stow to `~/.mcp.json` (user scope — must be at `~/`, not `~/.config/`).

### Web & Search
- **fetch**: Web content fetching (via uvx/mcp-server-fetch)
- **brave-search**: Web search via Brave Search API

### PostgreSQL Database Access

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

### Environment Variables

MCP servers require connection strings set in shell profile (`zsh/.config/zsh/exports.zsh`):

```bash
BRAVE_API_KEY          # Brave Search API
LOCAL_POSTGRES_URL     # postgresql://user:pass@localhost:5432/dbname
PROD_GAS_URL           # Production GAS database
PROD_SKJALFTALISA_URL  # Production earthquake database
PROD_TOS_URL           # Production TOS database
DEV_EPOS_URL           # Development EPOS database
DEV_GNSS_URL           # Development GNSS database
DEV_METRICS_URL        # Development metrics database
```

**Security**: Config uses `${VAR}` references — no credentials stored in this repository.
Production databases are read-only for safety.

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
