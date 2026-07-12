# Pi Global Context

## ⛔ Credential Security — Hard Rule

**NEVER expose in tool arguments, bash commands, file writes, or session output:**
- Passwords (database, service accounts, etc.)
- API keys or tokens
- Connection strings with embedded credentials

**Always use environment variables or `pass` for credentials:**
- Postgres: `PGPASSWORD` env var (psql reads it automatically) — see `pg.ts` extension
- API providers: `auth.json` with `!pass show <key>` format
- `~/.pgpass` for local psql connections

Session files are JSONL and can be exported/shared. A leaked credential becomes permanent.

### ⛔ NEVER run these (they dump secrets into the session)

These are hard-banned. There is no acceptable reason to run any of them:

- `env`, `printenv`, `export -p`, `set` — dump the whole environment (this leaked 6 API keys once via `env | grep "PI_"`, because `PI_` matches `*_API_KEY`).
- `env | grep ...` / `printenv | grep ...` — grep patterns match secret var names by accident. **Never grep the environment for anything.**
- `echo $ANY_API_KEY`, `echo $TOKEN`, `echo $*_KEY`, `cat` on files that hold secrets.
- `pass show <path>` **without** piping through redaction, or with its output printed to the terminal.
- Reading/`cat`ing `auth.json`, `.env`, `~/.pgpass`, `credentials*`, `*.vault`, private keys, or session `.jsonl` files and echoing their contents.
- Any `grep`/`sed`/`rg` over config or history that prints matched lines **without** a redaction filter (`.zsh_history`, `models.json`, `.mcp.json`, dotfiles).

### ✅ Safe patterns when you must touch a secret

- **Check a var is set without printing it:** `[ -n "$FOO_API_KEY" ] && echo set || echo unset`, or print only length/prefix: `echo "len ${#FOO} prefix ${FOO:0:4}…"`.
- **Use a key from `pass` for a live test:** load into a local var, use it, then `unset` it — never echo it:
  ```bash
  KEY=$(pass show tokens/foo_api_key | head -1)
  curl -s -o /dev/null -w '%{http_code}\n' https://api.example.com -H "Authorization: Bearer $KEY"
  unset KEY
  ```
- **Always pipe any command that might surface a secret through a redactor:** `... | sed -E 's/(sk-|BSA|fc-|glm-|[A-Za-z0-9_-]{24,})/<REDACTED>/g'`.
- **When searching configs/history**, redact values: `grep ... | sed -E 's/(=|: |show )("?)[A-Za-z0-9_.-]{16,}/\1\2<REDACTED>/g'`.
- **Discovering where a key lives:** grep for the *variable name* and *`pass` path* only — never the value.
- **Rotating keys:** verify with a live API call using the load-var-then-unset pattern; report only the HTTP status / error type, never the key.

### Rule of thumb

If a command's output could contain a secret, either don't run it, or pipe it through a redactor first. When unsure, assume it will leak and add the redactor. Treat every value that looks like a token (`sk-…`, `BSA…`, `fc-…`, long random strings) as radioactive.

## Available Tools

Custom tools from `bgo-toolkit` package:
- `pg_list_databases` — list available postgres databases
- `pg_describe_table` — inspect table schema (columns, types, indexes, row count)
- `pg_query` — execute SQL with auto-introspection and EXPLAIN validation
- `subagent` — delegate to scout, planner, reviewer, worker agents

## Default Model

**Copilot Claude Sonnet 4.6** is the default for interactive sessions. It's subscription-based so there's zero per-token cost to you — always the safe default for direct work.

The context-model extension auto-detects project complexity on startup and suggests switching to DeepSeek for simple/familiar projects.

## Model Optimization Framework

The agent system is designed to route tasks to the optimal LLM based on capability match:

- **Subscription models** (Copilot Sonnet 4.6): complex reasoning, security, architecture — no per-token cost
- **Mid-tier models** (Kimi K2.5): large context (256K) research, deep scouting
- **Budget models** (DeepSeek V3, Kimi K2 Turbo): scouting, simple changes, documentation
- **Free/local models** (Qwen 3.5, DeepSeek Coder V2 via Ollama): fallback when cloud is rate-limited

Adding a new model: edit `models.json` (live-reloads via `/model`), then optionally create an agent that uses it.

### Auto-Detection
- `/context-model` — analyze current project and recommend optimal default model
- On startup, detects project complexity and notifies if a cheaper model would suffice

## Model Modes & Auto-Routing (mode-router extension)

The `mode-router.ts` extension automatically routes the **main interactive model** across three modes:

| Mode | Trigger | Behavior |
|------|---------|----------|
| **online** | default (cloud reachable) | Your normal model choice stands; full cloud roster available |
| **offline** | cloud unreachable (auto-probed, 30s cache) | Silently switches main model to local `llama3.1:8b` + one-line notice; restores your cloud model when connectivity returns |
| **private** | `/private` command | Forces local-only even when online — nothing leaves the machine; `/private off` releases |

Commands: `/private` (toggle on-device mode), `/online` (force cloud + restore), `/mode` (show mode, connectivity, active model). Manual `/model` picks are respected — the router stops fighting you once you choose.

**Task-based distribution** is handled by the `orchestrator` agent (stable main model, no jarring mid-chat swaps), which decomposes work and dispatches each subtask to the cheapest capable specialist.

## Local Model Reality (benchmarked on RTX 2000 Ada, 8GB)

Tool-calling was benchmarked against Ollama's OpenAI endpoint (what Pi uses). **Only tool-capable models can drive Pi's agent loop:**

| Local model | Tool calls? | Speed | Role |
|-------------|-------------|-------|------|
| `llama3.1:8b` | ✅ yes | ~8s ★ fastest | Primary local agent (offline/private/fallback) |
| `hermes3:8b` | ✅ yes | ~10s | Secondary — function-calling finetune, good for richer tool schemas |
| `qwen3.5:latest` | ✅ yes | ~11s | Tertiary local agent |
| `qwen3:8b` | ✅ yes | ~21s slow | Backup |
| `granite3.3:8b` | ⚠️ unreliable | ~3s | Fast but drops/empties tool args — chat only, NOT agent loop |
| `qwen2.5-coder:7b` | ❌ emits raw JSON | — | Chat/completion only — NOT for agent loop |
| `ornith-16k` (capped) | ❌ no tool template | — | Chat/reasoning only |
| `deepseek-coder-v2:16b` | ❌ no tool template | — | Chat only + too big (spills VRAM) |

Ornith was capped to 16K context (`ornith-16k`) to fit 8GB VRAM. Never route agents to the ❌ models.

## Token-Cost Policy (non-subscription optimization)

Spend order for every task: **local ($0, private) → subscription ($0 marginal) → cheap-paid (DeepSeek) → premium-paid (Kimi/OpenRouter)**.

- Subscription Copilot is free at the margin → prefer it over cheap-paid DeepSeek for any non-trivial single task.
- Reserve **cheap-paid** for high-volume/parallel scouting where many Copilot calls would be slow/rate-limited.
- Reserve **local** for trivial or privacy-bound work (and all offline/private work).
- Reserve **premium-paid** for cases explicitly needing it.
- The `orchestrator` agent enforces this automatically.

## Agent Roster (15 agents)

### Exploration & Analysis

| Agent | Model | Context | Use for |
|-------|-------|---------|---------|
| **scout** | DeepSeek V4 Pro | 1M | Fast recon, small-medium codebases |
| **deep-scout** | DeepSeek V4 Pro | 1M | Multi-file analysis, large codebases, cross-cutting traces — #1 coding benchmarks |
| **researcher** | DeepSeek V4 Pro | 1M | Web research, source synthesis, tech evaluation — 1M context for many sources |
| **db-analyst** | DeepSeek V4 Pro | 1M | SQL queries, schema analysis, data exploration — coding proficiency → strong SQL |

### Design & Planning

| Agent | Model | Context | Use for |
|-------|-------|---------|---------|
| **architect** | GPT-5.5 (Copilot) | 400K | High-level design, tradeoff analysis — best reasoning, subscription |
| **planner** | Claude Opus 4.7 (Copilot) | 144K | Implementation plans — methodical, precise |

### Implementation

| Agent | Model | Context | Use for |
|-------|-------|---------|---------|
| **worker** | Claude Sonnet 4.6 (Copilot) | 1M | Complex implementation, multi-step refactors — known quantity |
| **quick-worker** | DeepSeek V4 Pro | 1M | Boilerplate, simple changes — #1 coding, cheap |
| **fallback-worker** | Llama 3.1 8B (local) | 32K | Offline / private / rate-limited work — fastest confirmed local tool-caller (~8s) |

### Orchestration

| Agent | Model | Context | Use for |
|-------|-------|---------|---------|
| **orchestrator** | Claude Sonnet 4.6 (Copilot) | 1M | Decompose multi-part tasks and dispatch each subtask to the optimal specialist/model; mode- & cost-aware |

### Quality

| Agent | Model | Context | Use for |
|-------|-------|---------|---------|
| **reviewer** | Claude Opus 4.7 (Copilot) | 144K | Code review, style, correctness — best precision |
| **auditor** | Claude Opus 4.7 (Copilot) | 144K | Security audit, vulnerability analysis — safety-critical |

### Meta

| Agent | Model | Context | Use for |
|-------|-------|---------|---------|
| **router** | DeepSeek V4 Pro | 1M | Task classification — recommends optimal agent/workflow |
| **docs-writer** | DeepSeek V4 Pro | 1M | READMEs, API docs, changelogs, code comments |

### Second Opinion (Diversity)

Kimi K2.5 (256K context, strong reasoning) is available for cases where model diversity helps — use as an alternative researcher or reviewer for independent second analysis. Not assigned to a permanent agent to keep the roster clean; invoke via `/model` switch or direct subagent call.

## Workflow Quick Reference

### By Complexity

```
Simple change     → /quick        (quick-worker only)
Standard feature  → /implement    (scout → planner → worker)
Complex feature   → /implement-deep (deep-scout → architect → planner → worker → auditor)
Not sure?         → /route <task>  (router classifies → follow recommendation)
```

### By Task Type

```
Web research      → /research <topic>
Architecture      → /architecture <design problem>
Security audit    → /audit <code scope>
Database work     → /db-analyze <db name>
Documentation     → /docs <what to document>
DB exploration    → /db-explore <db>
Review + fix      → /implement-and-review <task>
```

### Manual Agent Invocation

You can target any agent directly with the `subagent` tool:
```
subagent: auditor, task: Review the auth module for security issues
subagent: deep-scout, task: Map the entire codebase architecture
subagent: router, task: I need to add OAuth support to the API
```

## Model Cost Tiers

| Tier | Models | Cost |
|------|--------|------|
| **Copilot Subscription** | GPT-5.5, Claude Opus 4.7, Claude Sonnet 4.6, Gemini 3.1 Pro, GPT-5.4, GPT-5.3-codex + 12 more | $0 marginal (subscription) |
| **Budget** | DeepSeek V4 Pro (1M ctx, #1 coding) | ~$0.50-2.00/M tokens |
| **Free** | Ollama local models (Qwen, DeepSeek Coder) | $0 |

Copilot models available: claude-opus-4.7, claude-opus-4.6, claude-sonnet-4.6, gemini-3.1-pro-preview, gpt-5.5, gpt-5.4, gpt-5.3-codex, gpt-5.2-codex, gpt-5.1-codex-max, grok-code-fast-1, and 10+ more.

## Final Agent↔Model Map

```
DeepSeek V4 Pro (9 agents): scout, deep-scout, quick-worker, docs-writer,
                             db-analyst, researcher, router, + 2 existing

Copilot GPT-5.5 (1):       architect
Copilot Opus 4.7 (3):      planner, auditor, reviewer
Copilot Sonnet 4.6 (1):    worker
Ollama Qwen 3.5 (1):       fallback-worker
```

## Routing Principles

1. **Don't use a sledgehammer for a nail** — simple tasks go to cheap models
2. **Security-sensitive = always the best model** — auditor/architect on Sonnet
3. **Research benefits from large context** — researcher/deep-scout on Kimi K2.5 (256K)
4. **If unsure, ask the router** — `/route <task>` classifies and recommends

## Vault Integration

- `vault-lookup.py` at `/home/bgo/notes/bgovault/.scripts/vault-lookup.py`
- `learning-query.py` at `/home/bgo/notes/bgovault/.scripts/learning-query.py`
- Shared skills at `~/.claude/skills/` (30 of 40 work in Pi)

## Memory Bridge

Pi writes to `~/.claude/projects/<encoded-cwd>/memory/` — shared with Claude Code.
Both agents read from the same pool. Append-only.

## Capture Pipeline

Use `/capture <idea>` to drop ideas into Obsidian inbox for later sorting.
