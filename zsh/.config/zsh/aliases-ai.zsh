#!/bin/sh
# Alternate LLM backends for Claude Code (the Anthropic-format CLI).
#
# Claude Code speaks the Anthropic wire protocol. Both Moonshot (Kimi) and
# DeepSeek publish Anthropic-compatible endpoints, so we just redirect the base
# URL + auth token + per-tier model IDs and launch `claude` as usual.
#
# Notes:
#   - One backend is bound per PROCESS (env-at-launch), so these are wrappers,
#     not in-session switches. Quit and relaunch to change provider.
#   - Keys come from ~/.config/zsh/.zshenv (KIMI_API_KEY, DEEPSEEK_API_KEY);
#     never inline a key here — sessions get exported/shared.
#   - Claude Code selects models by TIER (opus/sonnet/haiku) + subagent model,
#     not a single ANTHROPIC_MODEL. We pin every tier so no request silently
#     falls back to Anthropic's servers.
#
# Verified against provider docs + live auth test 2026-08-02:
#   - Kimi has TWO separate billing systems with different keys/endpoints:
#       * Subscription (Moderato/Allegretto/...): api.kimi.com/coding, key from
#         kimi.com/code/console, models k3-256k / k3. THIS IS THE PAID PLAN.
#       * Pay-as-you-go API: api.moonshot.ai/anthropic, key KIMI_API_KEY,
#         model kimi-k3 — metered, currently no balance (429). See cc-kimi-api.
#   - Providers rename models often; if a model 404s, re-check
#     kimi.com/code/docs and api-docs.deepseek.com.

# --- Kimi Code SUBSCRIPTION (Moderato) — default ------------------------
# Key: KIMI_CODE_API_KEY, created at https://www.kimi.com/code/console.
# Models: k3-256k (Moderato, 256k ctx) | k3 (full 1M ctx, ~2x quota).
# Override the model with CC_KIMI_MODEL.
cc-kimi() {
  if [ -z "$KIMI_CODE_API_KEY" ]; then
    echo "cc-kimi: KIMI_CODE_API_KEY is not set." >&2
    echo "         Create a subscription key at https://www.kimi.com/code/console" >&2
    echo "         and add it (like KIMI_API_KEY) in ~/.config/zsh/.zshenv" >&2
    return 1
  fi
  local model="${CC_KIMI_MODEL:-k3-256k}"
  ANTHROPIC_BASE_URL="https://api.kimi.com/coding" \
  ANTHROPIC_AUTH_TOKEN="$KIMI_CODE_API_KEY" \
  ANTHROPIC_MODEL="$model" \
  ANTHROPIC_DEFAULT_OPUS_MODEL="$model" \
  ANTHROPIC_DEFAULT_SONNET_MODEL="$model" \
  ANTHROPIC_DEFAULT_HAIKU_MODEL="$model" \
  CLAUDE_CODE_SUBAGENT_MODEL="$model" \
    claude "$@"
}

# --- Kimi pay-as-you-go API (metered) — fallback ------------------------
# Uses KIMI_API_KEY on the global platform. Only useful with PAYG balance.
cc-kimi-api() {
  if [ -z "$KIMI_API_KEY" ]; then
    echo "cc-kimi-api: KIMI_API_KEY is not set (see ~/.config/zsh/.zshenv)" >&2
    return 1
  fi
  local model="${CC_KIMI_MODEL:-kimi-k3}"
  ANTHROPIC_BASE_URL="https://api.moonshot.ai/anthropic" \
  ANTHROPIC_AUTH_TOKEN="$KIMI_API_KEY" \
  ANTHROPIC_MODEL="$model" \
  ANTHROPIC_DEFAULT_OPUS_MODEL="$model" \
  ANTHROPIC_DEFAULT_SONNET_MODEL="$model" \
  ANTHROPIC_DEFAULT_HAIKU_MODEL="$model" \
  CLAUDE_CODE_SUBAGENT_MODEL="$model" \
    claude "$@"
}

# --- DeepSeek -----------------------------------------------------------
# Two tiers: deepseek-v4-pro (opus/sonnet) | deepseek-v4-flash (haiku/subagents).
# Override with CC_DEEPSEEK_PRO_MODEL / CC_DEEPSEEK_FLASH_MODEL.
cc-deepseek() {
  if [ -z "$DEEPSEEK_API_KEY" ]; then
    echo "cc-deepseek: DEEPSEEK_API_KEY is not set (see ~/.config/zsh/.zshenv)" >&2
    return 1
  fi
  local pro="${CC_DEEPSEEK_PRO_MODEL:-deepseek-v4-pro}"
  local flash="${CC_DEEPSEEK_FLASH_MODEL:-deepseek-v4-flash}"
  ANTHROPIC_BASE_URL="https://api.deepseek.com/anthropic" \
  ANTHROPIC_AUTH_TOKEN="$DEEPSEEK_API_KEY" \
  ANTHROPIC_MODEL="$pro" \
  ANTHROPIC_DEFAULT_OPUS_MODEL="$pro" \
  ANTHROPIC_DEFAULT_SONNET_MODEL="$pro" \
  ANTHROPIC_DEFAULT_HAIKU_MODEL="$flash" \
  CLAUDE_CODE_SUBAGENT_MODEL="$flash" \
  CLAUDE_CODE_EFFORT_LEVEL="${CLAUDE_CODE_EFFORT_LEVEL:-max}" \
    claude "$@"
}

# Short forms, matching the cc/cca/ccf family in aliases-claude.zsh
alias cck='cc-kimi'
alias ccd='cc-deepseek'
