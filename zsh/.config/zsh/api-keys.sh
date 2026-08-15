# api-keys.sh — decrypt API keys from `pass` into the environment, once.
#
# Sourced by ~/.profile at login so the whole session (sway → every shell)
# inherits them, and fallback-sourced by ~/.zshenv for contexts that don't
# read ~/.profile (SSH/tty), or if the login-time decryption failed.
#
# Why not inline in ~/.zshenv? .zshenv runs for EVERY zsh instance
# (interactive shells, scripts, every subshell). The ~11 `pass show` calls
# here — one gpg decryption each, ~0.3s — added ~3s to EVERY prompt, and
# much more at boot while gpg-agent warmed up / the key was locked.
#
# Guard: skip when the keys are already present (inherited from the session,
# or loaded by an ancestor shell). If a previous load produced empty values
# (e.g. gpg-agent wasn't unlocked yet), we retry rather than caching nothing.
if [ -n "${DEEPSEEK_API_KEY:-}" ] && [ -n "${ANTHROPIC_API_KEY:-}" ]; then
    return 0
fi

export ANTHROPIC_API_KEY=$(pass show tokens/anthropic_api_key 2>/dev/null || echo "")
export BRAVE_API_KEY=$(pass show tokens/brave_api 2>/dev/null || echo "")
export KIMI_API_KEY=$(pass show tokens/kimi_api_key 2>/dev/null || echo "")
export KIMI_CODE_API_KEY=$(pass show tokens/kimi_code_api_key 2>/dev/null || echo "")
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
