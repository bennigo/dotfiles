# Crush Configuration

Multi-provider AI coding assistant (terminal TUI), successor to OpenCode.
Installed via npm (`@charmland/crush`), config deployed via stow.

## Provider Setup

Currently configured with **Ollama local models only** (no cloud API keys yet).

### Active Providers

| Provider | Type | Models |
|----------|------|--------|
| Ollama (local) | `openai-compat` | DeepSeek Coder V2 16B (large), Llama 3.1 8B (small), DeepSeek Coder 6.7B |

### Adding Cloud Providers

Set environment variables in `zsh/.config/zsh/exports.zsh`, then add provider blocks to `crush.json`:

| Provider | Env Variable | Type |
|----------|-------------|------|
| Anthropic | `ANTHROPIC_API_KEY` | `anthropic` |
| OpenAI | `OPENAI_API_KEY` | `openai` |
| Google Gemini | `GEMINI_API_KEY` | `gemini` |
| Groq | `GROQ_API_KEY` | `openai-compat` |
| OpenRouter | `OPENROUTER_API_KEY` | `openai-compat` |
| GitHub Copilot | OAuth (built-in) | `crush login copilot` |

## MCP Servers

Subset of Claude Code's MCP servers configured for Crush:

- **fetch** — Web content fetching (uvx/mcp-server-fetch)
- **brave-search** — Web search via Brave Search API

Database and Google Workspace MCP servers are intentionally omitted (Claude Code handles those).

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
Ctrl+O                   # Switch model mid-session (in TUI)
```

## Config Location

- Source: `.dotfiles/crush/.config/crush/crush.json`
- Deployed: `~/.config/crush/` (stow symlink)
- Data: `~/.local/share/crush/` (sessions, SQLite DB)

## Cross-References

- **Claude Code MCP config**: `claude-code/CLAUDE.md`
- **Ollama setup**: `ollama/README.md`
- **Shell env vars**: `zsh/.config/zsh/exports.zsh`
