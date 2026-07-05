export ZDOTDIR="${HOME}/.config/zsh"

. "$HOME/.cargo/env"

. "$HOME/.local/bin/env"

# API keys from pass — available to all zsh instances (Pi, Crush, Claude Code)
# Fail silently if GPG agent isn't unlocked (e.g., during early boot)
export ANTHROPIC_API_KEY=$(pass show tokens/anthropic_api_key 2>/dev/null || echo "")
export BRAVE_API_KEY=$(pass show tokens/brave_api 2>/dev/null || echo "")
export KIMI_API_KEY=$(pass show tokens/kimi_api_key 2>/dev/null || echo "")
export OPENROUTER_API_KEY=$(pass show openrouter/api_key 2>/dev/null || echo "") 
DEEPSEEK_API_KEY=$(pass show tokens/deepseek_api_key 2>/dev/null || true)
if [ -n "$DEEPSEEK_API_KEY" ]; then
    export DEEPSEEK_API_KEY
else
    unset DEEPSEEK_API_KEY
fi
export GOOGLE_MCP_CLIENT_ID=$(pass show tokens/google_mcp_claude_client_id 2>/dev/null || echo "")
export GOOGLE_MCP_CLIENT_SECRET=$(pass show tokens/google_mcp_claude_client_secret 2>/dev/null || echo "")
export ZHIPU_API_KEY=$(pass show tokens/zhipu_api_key 2>/dev/null || echo "")
export FIRECRAWL_API_KEY=$(pass show tokens/firecrawl_api_key 2>/dev/null || echo "")
export ZAI_CODING_CN_API_KEY=$(pass show tokens/zhipu_api_key 2>/dev/null || echo "")
