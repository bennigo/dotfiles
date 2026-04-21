#!/usr/bin/env bash
# UserPromptSubmit hook that nudges toward effort/model escalation when the
# user's prompt contains strong signals that a previous approach isn't
# converging (e.g. "still not working", "same error", "didn't work").
#
# Output is appended to the prompt as additional context for Claude.
# Conservative matching — only fires on strong struggle signals to avoid noise.
#
# Wired into ~/.claude/settings.json under hooks.UserPromptSubmit.

set -eu

# Claude Code sends hook input as JSON on stdin for UserPromptSubmit.
# Field of interest: .prompt
input=$(cat)
prompt=$(printf '%s' "$input" | jq -r '.prompt // empty' 2>/dev/null || true)

[ -z "$prompt" ] && exit 0

# Case-insensitive strong-signal regex. Grouped by category:
#   - "still <not working / broken / failing>"
#   - "same <error / issue / problem / failure>"
#   - "keeps <failing / breaking / erroring>"
#   - "try <again / differently / another approach>"
#   - "doesn't work <either / again>"
#   - "didn't <work / fix it>"
#   - "no luck" / "giving up"
pattern='(still [^.]*(not working|isn'"'"'t working|doesn'"'"'t work|broken|failing|wrong))|(same (error|issue|problem|failure|bug))|(keeps? (failing|breaking|crashing|erroring))|(try (again|differently|another (approach|way)))|(doesn'"'"'t work (either|again))|(didn'"'"'t (work|fix))|(no luck (with|so far))|(giving up on)'

if printf '%s' "$prompt" | grep -qiE "$pattern"; then
  cat <<'EOF'
💡 [effort-nudge hook] Strong struggle signal detected in the user's prompt.
Before retrying a similar approach, consider escalating:
  1. Call advisor() — stronger reviewer sees the full transcript (cheapest)
  2. /model opus && /effort xhigh — switch session to higher tier (persistent)
  3. /effort max — one-session maximum thinking budget (session-only, auto-resets)
  4. Or add "ultrathink" to a prompt for a single deep-reasoning turn

This is advisory from a prompt-regex hook — apply judgment, not reflex.
EOF
fi

exit 0
