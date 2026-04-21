#!/bin/sh
# Claude Code launch-time effort/model selection.
# Baseline is set in ~/.claude/settings.json (Sonnet @ high).
# Use these aliases when you know up front the task needs a different tier.
# For in-session switching (Neovim/tmux/long sessions), use slash commands
# /cruise, /accelerate, /floorit, /stuck — those travel with you into any client.

# Cruise — plain launch, uses settings.json baseline (Sonnet @ high)
alias cc='claude'

# Accelerate — Opus with sensible effort for non-trivial work
alias cca='CLAUDE_CODE_EFFORT_LEVEL=high claude --model opus'

# Floor it — Opus at xhigh, for architectural/gnarly sessions
alias ccf='CLAUDE_CODE_EFFORT_LEVEL=xhigh claude --model opus'

# Plan-then-execute hybrid — Opus plans, Sonnet executes
alias ccp='claude --model opusplan'

# Cheap exploration — Sonnet at medium for research/survey work
alias ccl='CLAUDE_CODE_EFFORT_LEVEL=medium claude --model sonnet'
