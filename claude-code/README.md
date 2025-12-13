# Claude Code Configuration

Configuration for Claude Code CLI tool and MCP (Model Context Protocol) servers.

## Files

- `.mcp.json` - MCP server configurations (deployed to `~/.mcp.json` for user scope)

## MCP Servers

### Web & Search
- **fetch**: Basic web content fetching (via uvx/mcp-server-fetch)
- **brave-search**: Web search via Brave Search API

### PostgreSQL Database Access

Multiple PostgreSQL database connections configured for various projects:

- **postgres-local**: Local development database (read-write)
- **postgres-gas-readonly**: Production GAS database (read-only)
- **postgres-skjalftalisa-readonly**: Production earthquake database (read-only)
- **postgres-tos-readonly**: Production TOS database (read-only)
- **postgres-epos-readonly**: Development EPOS database (read-only)
- **postgres-gnss-readonly**: Development GNSS database (read-only)
- **postgres-metrics-readonly**: Development metrics database (read-only)

## Environment Variables Required

The following environment variables must be set for MCP servers to function:

```bash
# Brave Search API
export BRAVE_API_KEY="your-brave-api-key"

# PostgreSQL connection strings
export LOCAL_POSTGRES_URL="postgresql://user:pass@localhost:5432/dbname"
export PROD_GAS_URL="postgresql://user:pass@host:port/gas"
export PROD_SKJALFTALISA_URL="postgresql://user:pass@host:port/skjalftalisa"
export PROD_TOS_URL="postgresql://user:pass@host:port/tos"
export DEV_EPOS_URL="postgresql://user:pass@host:port/epos"
export DEV_GNSS_URL="postgresql://user:pass@host:port/gnss"
export DEV_METRICS_URL="postgresql://user:pass@host:port/metrics"
```

**Note**: These should be set in your shell profile (e.g., `~/.config/zsh/exports.zsh`) or via a secrets management system. Never commit actual credentials to this repository.

## Security Notes

- Configuration uses environment variable references (e.g., `${BRAVE_API_KEY}`)
- No credentials are stored in this repository
- Production databases are configured as read-only for safety
- PostgreSQL connection URLs should follow standard format: `postgresql://user:password@host:port/database`

## Deployment

This configuration is deployed via GNU Stow as part of the dotfiles repository:

```bash
cd ~/.dotfiles
stow claude-code
```

This creates `~/.mcp.json` → `.dotfiles/claude-code/.mcp.json` symlink.

Ansible bootstrap automatically deploys this with other dotfiles.

**Important**: The file must be at `~/.mcp.json` (user scope), NOT `~/.config/claude-code/mcp.json`.

## Usage

Once deployed and environment variables are set, Claude Code will automatically use these MCP server configurations for enhanced capabilities:

- Web content fetching and search
- Direct database queries and schema inspection
- SQL query assistance and optimization

## Cross-References

- **Main dotfiles**: `~/.dotfiles/CLAUDE.md`
- **Shell environment**: `~/.dotfiles/zsh/.config/zsh/exports.zsh`
- **Database setup**: `~/.dotfiles/ansible/DATABASE_SETUP.md`
