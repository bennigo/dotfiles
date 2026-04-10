# Crush Configuration

Multi-provider AI coding assistant (terminal TUI), successor to OpenCode.
Installed via npm (`@charmland/crush`), config deployed via stow.

## Provider Setup

### Active Providers

| Provider | Type | Models |
|----------|------|--------|
| GitHub Copilot | OAuth (built-in) | Claude Sonnet 4.6 (large default), Gemini 2.5 Pro (small default), + 20 more |
| Ollama (local) | `openai-compat` | DeepSeek Coder V2 16B, Llama 3.1 8B, DeepSeek Coder 6.7B |

### Adding More Cloud Providers

Set environment variables in `zsh/.config/zsh/exports.zsh`, then add provider blocks to `crush.json`:

| Provider | Env Variable | Type |
|----------|-------------|------|
| Anthropic | `ANTHROPIC_API_KEY` | `anthropic` |
| OpenAI | `OPENAI_API_KEY` | `openai` |
| Google Gemini | `GEMINI_API_KEY` | `gemini` |
| Groq | `GROQ_API_KEY` | `openai-compat` |
| OpenRouter | `OPENROUTER_API_KEY` | `openai-compat` |

## MCP Servers

Full parity with Claude Code's MCP servers (except Google Workspace — held back pending
permission boundary testing with non-Claude models):

- **fetch** — Web content fetching (uvx/mcp-server-fetch)
- **brave-search** — Web search via Brave Search API
- **postgres-local** — Local development database (read-write)
- **postgres-gas-readonly** — Production GAS database
- **postgres-skjalftalisa-readonly** — Production earthquake database
- **postgres-tos-readonly** — Production TOS database
- **postgres-epos-readonly** — Development EPOS database
- **postgres-gnss-readonly** — Development GNSS database
- **postgres-metrics-readonly** — Development metrics database

## Shared Context

Crush reads `CLAUDE.md` files from the working directory via the `context_paths` option.
This means the existing CLAUDE.md hierarchy (project rules, coding standards, domain knowledge)
is shared between Claude Code and Crush automatically — no duplication needed.

Google Workspace MCP is intentionally omitted until permission boundary behavior is verified.

## LSP Integration

Auto-LSP enabled. Explicit configs for:
- **Python** — Pyright
- **Lua** — lua-language-server

## Usage

```bash
crush                    # Interactive TUI
crush run "prompt"       # Non-interactive
crush --continue         # Resume last session
crush login copilot      # Authenticate GitHub Copilot
Ctrl+L                   # Switch model mid-session (in TUI)
Ctrl+O                   # Open external editor for prompt
```

## Config Location

- Source: `.dotfiles/crush/.config/crush/crush.json`
- Deployed: `~/.config/crush/` (stow symlink)
- Data: `~/.local/share/crush/` (sessions, SQLite DB)

## Cross-References

- **Claude Code MCP config**: `claude-code/CLAUDE.md`
- **Ollama setup**: `ollama/README.md`
- **Shell env vars**: `zsh/.config/zsh/exports.zsh`
