# pi-subagents local patches

These patch `node_modules/pi-subagents` in place. **They are lost on every npm reinstall or
pi upgrade** and must be re-applied.

Apply after any npm reinstall or pi upgrade:

    python3 ~/.dotfiles/pi/.pi/patches/apply.py           # patch in place
    python3 ~/.dotfiles/pi/.pi/patches/apply.py --check   # dry run

The script is idempotent: it reports `already patched` when present, and fails loudly if an
upstream change moved the anchor (re-derive the patch rather than guessing). It keeps a
`.prepatch` copy beside each file it touches.

Then verify syntax and restart pi — the extension is loaded at startup, so a running session
keeps using the old code until it reloads:

    node --check ~/.config/pi/agent/npm/node_modules/pi-subagents/src/runs/shared/subagent-control.js
    node --check ~/.config/pi/agent/npm/node_modules/pi-subagents/src/runs/background/subagent-runner.js

## Why

`needs_attention` fired on every workflow child ~60s after launch (6 false signals in one
session, one at the exact moment a lane completed). Two activity signals were both dead for
workflow children:

1. `output-<index>.log` never exists. Across 369 async run dirs: `{0 logs: 47, 1 log: 324}` —
   single-agent runs write `output-0.log`, workflow runs write none. `fs.statSync` threw
   ENOENT and the catch ignored it (`if (error.code !== "ENOENT")`).
2. `step.lastActivityAt` is never populated — 0 of 5-16 steps across four workflow runs.

`deriveActivityState` therefore fell back to `startedAt`, with an unscaled 60s default
(`thinking` was `None` everywhere). 60s after launch, any gap between tool calls — a model
generating a long report — looked idle.

## 0001 — no activity observed is not idleness
`deriveActivityState` returns `undefined` when `lastActivityAt` is undefined, instead of
measuring from `startedAt`. A child that has reported nothing cannot be judged stuck.
(Note: the async call site always passes a number, so this guards the contract rather than
fixing the symptom on its own.)

## 0002 — real activity heartbeat, and stop swallowing ENOENT
`stepOutputActivityAt` also takes the mtime of `status.json`, which IS rewritten on every
turn and tool transition (`writeStatusPayload` → `runPersistence.write`). That gives a real
heartbeat where none existed. The ENOENT for a missing output log is now reported once per
path instead of silently ignored.

Trade-off: `status.json` is run-level, so any active step keeps its siblings looking active.
Per-step stall detection is weakened; false alarms are eliminated. For workflow fan-out that
is the right trade — under-alarm rather than cry wolf.

## Not fixed
Streamed native deltas are not counted as activity. `onExternalStreamActivity` is wired for
external-CLI children only, and there is no native equivalent to hook in 0.79.1.

## Belt and braces
`~/.pi/agent/extensions/subagent/config.json` (symlinked from this dotfiles package) raises
`control.needsAttentionAfterMs` to 300000.
