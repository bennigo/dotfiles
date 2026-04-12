# agent

OpenClaw AI agent with user isolation. Creates a restricted `openclaw-agent` system
user (no sudo, no docker group), installs Node.js + agent npm packages, extracts
API keys from ansible-vault, and generates an operational guide.

Supports two modes via `agent_dual_use`:
- **Dedicated** (`agent_server` profile) — full firewall lockdown, Tailscale, bgovault read-only
- **Dual-use** (`agent_addon` profile) — skips firewall/vault/home-chmod, safe on live desktop

## When to run

After `base` and `credentials`. Use `--tags agent` to run in isolation.

```bash
# Dual-use (on existing desktop):
ansible-playbook bootstrap.yml --extra-vars "@profiles/agent_addon.yml" --tags agent

# Dedicated server:
ansible-playbook bootstrap.yml --extra-vars "@profiles/agent_server.yml" --limit agent_servers
```

## What it creates

- `openclaw-agent` user (0700 home, no sudo, no docker)
- `/opt/openclaw/{logs,data,config}` workspace
- Node.js via fnm + `@anthropic-ai/claude-code` + `openclaw` npm packages
- `/opt/openclaw/config/agent.env` (API keys, mode 0600)
- `/etc/logrotate.d/openclaw-agent`
- `~/AGENT_SERVER_GUIDE.md` (progressive trust roadmap)
- Optional: Tailscale, UFW firewall, bgovault read-only (dedicated mode only)

## Dependencies

- `base`, `credentials`

## Key variables

- `agent_user` — default `"openclaw-agent"`
- `agent_workspace` — default `"/opt/openclaw"`
- `agent_dual_use` — default `false` (set `true` in `agent_addon` profile)
- `agent_npm_packages` — `["@anthropic-ai/claude-code", "openclaw"]`
- `features.setup_tailscale`, `features.setup_firewall`

## Verification

```bash
getent passwd openclaw-agent
sudo -l -U openclaw-agent               # "not allowed"
groups openclaw-agent                    # should NOT include docker
sudo -u openclaw-agent ls /home/bgo     # Permission denied
```

## See also

- [`../profiles/agent_addon.yml`](../profiles/agent_addon.yml) — dual-use profile
- [`../profiles/agent_server.yml`](../profiles/agent_server.yml) — dedicated profile
- [`../FIRST_RUN.md`](../FIRST_RUN.md) — fresh 26.04 two-phase bootstrap
- [`../../PLAYBOOK_GUIDE.md`](../../PLAYBOOK_GUIDE.md) — Recipe 3 (add agent to existing desktop)
