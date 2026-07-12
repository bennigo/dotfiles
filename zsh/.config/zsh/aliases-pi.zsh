#!/bin/sh
# Pi coding agent — launch-time helpers.
# Complements the mode-router extension (/private, /online, /mode) and the
# local-model setup benchmarked on the RTX 2000 Ada (8GB).

# pilocal — clean, isolated LOCAL-only Pi session for an 8B model.
#   - runs in a scratch dir (default /tmp) so big AGENTS.md/CLAUDE.md context
#     files are not loaded; pass a dir as $1 to work elsewhere.
#   - strips context files / skills / prompt templates to preserve the tiny
#     8B context budget.
#   - uses the 8K-context llama3.1 variant (ollama/llama3.1-8k), a lean toolset,
#     and an ephemeral (unsaved) session.
# Usage: pilocal            # session in /tmp
#        pilocal ~/proj     # session in ~/proj
#        PILOCAL_MODEL=ollama/hermes3:8b pilocal   # override model
pilocal() {
  local dir="${1:-/tmp}"
  local model="${PILOCAL_MODEL:-ollama/llama3.1-8k:latest}"
  ( cd "$dir" 2>/dev/null || { echo "pilocal: no such dir: $dir" >&2; return 1; }
    pi --model "$model" \
       --no-context-files \
       --no-skills \
       --no-prompt-templates \
       --no-session \
       --tools read,bash,ls,edit,write )
}

# pilocalchat — same, but pure chat (no tools) for maximum context headroom.
pilocalchat() {
  local dir="${1:-/tmp}"
  local model="${PILOCAL_MODEL:-ollama/llama3.1-8k:latest}"
  ( cd "$dir" 2>/dev/null || { echo "pilocalchat: no such dir: $dir" >&2; return 1; }
    pi --model "$model" \
       --no-context-files --no-skills --no-prompt-templates \
       --no-session --no-tools )
}
