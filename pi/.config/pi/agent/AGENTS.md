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

**Copilot Claude Sonnet 5** is the session default (`settings.json`). It's subscription-based so there's zero per-token cost to you — always the safe default for direct work. (Anthropic models are otherwise used mostly via Claude Code; pi's free "think harder" lane is GLM.)

The context-model extension auto-detects project complexity on startup and notes when cheap DeepSeek Flash would suffice. The model-tiers extension provides instant switching:

| Key | Command | Model | Cost |
|-----|---------|-------|------|
| Ctrl+1 | `/std` | Claude Sonnet 5 (Copilot) | $0 — default |
| Ctrl+2 | `/flash` | DeepSeek V4.1 Flash | very cheap (~$0.30/$1.20 per M) — alternative default for familiar/high-volume work |
| Ctrl+3 | `/pro` | DeepSeek V4 Pro | paid (~$1.32/$3.96 per M) — special occasions, parallel fanout |
| Ctrl+4 | `/deep` | GLM-5.3-Highspeed (z.ai) | $0 (per models.json) — strong reasoning, 1M ctx |
| Ctrl+5 | `/free` | Kimi K3 1M (subscription) | $0 — biggest context |
| Ctrl+6 | `/glm` | GLM-5.3 (z.ai) | paid flagship — when Highspeed quality isn't enough |
| Ctrl+7 | `/codex` | GPT-6.1 Sol (openai-codex) | $0 — work ChatGPT Team/Business seat, 500K ctx |
| — | `/local` | Llama 3.1 8B (Ollama) | $0 — offline/private |
| — | `/tier` | show the ladder + active model | — |
| — | `/quota` | show/clear the quota-fallback state (`restore` / `clear`) | — |

**Copilot quota fallback (automatic).** Copilot returns `402 quota_exceeded` when the monthly premium
budget is gone, and `429 rate limited` when transient. On either, `model-tiers.ts` switches to
**DeepSeek V4.1 Flash** so work continues, and remembers where it came from:

- **402 (quota)** — no auto-restore (resets monthly). Persisted to disk, so a *new* session won't burn a
  request rediscovering the exhausted quota. `/quota restore` when it's back.
- **429 (rate limit)** — auto-restore attempted after a 10m cooldown, doubling up to 60m on repeat failures.

Only `github-copilot`, `kimi-coding` and `openai-codex` (subscription providers) trigger the fallback; paid providers
never do. This is the **only** place that auto-switches a model — the trivial/heavy hints stay suggest-only.

**Kimi K3 1M** is the free large-context lane (`Ctrl+5`) and powers scout, deep-scout, researcher,
db-analyst, router, and docs-writer.

Suggest-only hints fire once per session when a trivial prompt hits a paid model or a heavy prompt hits a cheap lane. The only automatic switches are mode-router's offline/private handling and the Copilot quota fallback above.

## Model Optimization Framework

The agent system is designed to route tasks to the optimal LLM based on capability match:

- **Subscription models** (Copilot Sonnet 5/4.6, Opus 4.8, GPT-5.3-Codex; Kimi K3 1M; GLM-5.3-Highspeed): everything non-trivial — no per-token cost
- **Budget models** (DeepSeek V4.1 Flash): high-volume/simple work, familiar codebases, parallel fanout
- **Premium paid** (DeepSeek V4 Pro, OpenRouter frontier): explicit request only
- **Free/local models** (Llama 3.1 8B, Qwen 3.5 via Ollama): offline/private/rate-limited fallback

Adding a new model: edit `models.json` (live-reloads via `/model`), then optionally create an agent that uses it.

⚠️ **Do not redefine a built-in provider's models** (e.g. `deepseek`). A `models` array merges by `id`, so a custom entry with the same `id` **replaces** the built-in and drops its correct `compat`/`maxTokens` — this is what silently degraded DeepSeek to a 32.8K output cap and missing `thinkingFormat`/`requiresReasoningContentOnAssistantMessages`. To tweak a built-in model, use `modelOverrides`; to inherit pi's catalog, omit `models` from the provider block.

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

Spend order for every task: **local ($0, private) → `$0` subscription quota pools → cheap-paid (DeepSeek) → premium-paid (OpenRouter, Kimi 1M)**.

**Drain the `$0` quotas first — an unused quota is wasted value.** It resets and is gone, so route work to the `$0` pools until they are exhausted, and treat DeepSeek as the *cheap overflow*, not the default. Three independent `$0` pools exist, and spreading across them also buys failure isolation:

| `$0` pool | Model | Context | Notes |
|---|---|---|---|
| OpenAI Codex (company sub) | `openai-codex/gpt-6.1-sol`, `gpt-6-astra` | 500K / 272K | quota-capped; heavy reasoning |
| GLM-Highspeed (z.ai) | `zai/glm-5.3-highspeed` | 1M | the long-context research pool |
| Kimi | `kimi-coding/k3-256k` | 256K | 5-hour window; short-context lanes |

- **DeepSeek is cheap enough to use freely** and is the right pick for high-volume trivial work and for overflow once the `$0` pools are spent — but it should not be the *default* while quota remains.
- **Reserve `local` for trivial or privacy-bound work** (and all offline/private work).
- **Reserve premium-paid** (OpenRouter frontier, `kimi-coding/k3` 1M, `zai/glm-5.3` non-highspeed) for cases explicitly needing it.
- The `orchestrator` agent enforces this automatically.

⚠️ **Metered-tier trap:** several `$0` models sit beside near-identical *paid* siblings and the paid one is the obvious-looking choice — `kimi-coding/k3` ($3/$15) vs `k3-256k` (**$0**); `zai/glm-5.3` ($1.40/$4.40) vs `zai/glm-5.3-highspeed` (**$0**, same 1M ctx). The research lanes ran on paid Kimi for weeks for exactly this reason. **Check the `cost` field in `models-store.json` before assigning a lane.**

**Subagent caveat:** children do **not** inherit `model-tiers`' automatic quota fallback (that covers the main model only), so a lane on an exhausted pool simply fails. Pool diversity is the only protection at the subagent layer.

⚠️ **Tool-surface caveat: what a child can actually call.** Verified 2026-10-16 against `pi-subagents`:

| Capability | Foreground child (`async: false`) | Background child (default) |
|---|---|---|
| `mcp:*` direct MCP tools | ✗ | **✗ — unavailable either way** |
| Extension tools (e.g. `vault_lookup`) | ✗ | ✓ |
| `bash`, `read`, `web_fetch`, core tools | ✓ | ✓ |

- **Never launch a child with `async: false` when it needs an extension or MCP tool.** Foreground children never load the parent's ambient extensions; only background children do. The failure is a terse "these child tools were unavailable" — easy to misread as a config bug.
- **`mcp:` selectors cannot be made to work by any launch mode.** MCP servers registered at runtime by `pi-mcp-adapter` are not resolvable at child launch (`Unresolved MCP direct-tool selectors`). Prefer giving the child the **underlying API via `bash`** instead — e.g. the Zotero local HTTP API on `localhost:23119`, which needs no MCP at all. Runtime-registered servers would need a host/pi-mcp-adapter handoff before child launch, which is not wired up here.
- Any agent whose work matters should degrade to `bash` rather than depend on an MCP tool.

## Agent Roster (16 agents)

### Exploration & Analysis

| Agent | Model | Context | Use for |
|-------|-------|---------|---------|
| **scout** | GLM-5.3-Highspeed (z.ai CN plan, $0) | 1M | Fast recon, small-medium codebases |
| **deep-scout** | GLM-5.3-Highspeed (z.ai, $0) | 1M | Multi-file analysis, large codebases, cross-cutting traces |
| **researcher** | GLM-5.3-Highspeed (z.ai, $0) | 1M | Web research, source synthesis, tech evaluation |
| **db-analyst** | Kimi K3 256K ($0) | 256K | SQL queries, schema analysis, data exploration |

### Design & Planning

| Agent | Model | Context | Use for |
|-------|-------|---------|---------|
| **architect** | GPT-6.1 Sol (OpenAI Codex) | 500K | High-level design, tradeoff analysis — $0 subscription |
| **planner** | GPT-6.1 Sol (OpenAI Codex) | 500K | Implementation plans — methodical, precise |

### Implementation

| Agent | Model | Context | Use for |
|-------|-------|---------|---------|
| **worker** | GPT-6.1 Sol (OpenAI Codex, $0) | 500K | Complex implementation, multi-step refactors |
| **quick-worker** | DeepSeek V4.1 Flash | 1M | Boilerplate, simple changes — very cheap paid |
| **fallback-worker** | Llama 3.1 8B (local) | 4K | Offline / private / rate-limited work — fastest confirmed local tool-caller (~8s) |

### Content Enrichment

| Agent | Model | Context | Use for |
|-------|-------|---------|---------|
| **enricher** | DeepSeek V4 Pro | 1M | Transcript enrichment pipeline — speaker ID, filing, URL cleanup, wikilink weaving, claim extraction, cross-refs. **Default lane for `/transcribe` Step 2.** |

> Enrichment is high-volume prose work where a frontier model buys nothing: the expensive failure mode is *fabrication*, not shallow reasoning, so the agent prompt carries hard anti-confabulation rules instead of a costly model. Route deep enrichment here by default; escalate to `worker` only for a transcript that needs genuine cross-document reasoning.
>
> **Do not downgrade `enricher` to DeepSeek Flash.** Pro-over-Flash is a deliberate reliability decision (agreed 2026-09-19), not an oversight: prior audits found batch-enriched notes inventing a person's death, missing a death date by eight weeks, and inflating roles. The ~4× cost saving is not worth re-introducing that failure mode. Improve reliability via the prompt's anti-confabulation rules, not by changing the model.

### Orchestration

| Agent | Model | Context | Use for |
|-------|-------|---------|---------|
| **orchestrator** | GPT-6.1 Sol (OpenAI Codex, $0) | 500K | Decompose multi-part tasks and dispatch each subtask to the optimal specialist/model; mode- & cost-aware |

### Quality

| Agent | Model | Context | Use for |
|-------|-------|---------|---------|
| **reviewer** | GPT-6.1 Sol (OpenAI Codex, $0) | 500K | Code review, style, correctness — best precision |
| **auditor** | GPT-6 Astra (OpenAI Codex, $0) | 272K | Security audit, vulnerability analysis — safety-critical. The one flagship-tier lane; kept there deliberately since audit errors are the most expensive to miss |

### Meta

| Agent | Model | Context | Use for |
|-------|-------|---------|---------|
| **router** | DeepSeek V4.1 Flash | 1M | Task classification — recommends optimal agent/workflow. Cheap enough that the metered cost is irrelevant for one-line output |
| **docs-writer** | GLM-5.3-Highspeed (z.ai CN plan, $0) | 1M | READMEs, API docs, changelogs, code comments |

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
| **OpenAI Codex (company subscription)** | GPT-6.1 Sol, GPT-6 Astra, GPT-6 Sol/Luna, GPT-5.6 family | $0 marginal within quota |
| **GLM-Highspeed (z.ai)** | GLM-5.3-Highspeed, GLM-5.2-Highspeed — **1M context** | $0 marginal within quota |
| **Kimi (subscription)** | Kimi K3-256K only | $0 marginal within quota |
| **Free / local** | Ollama (Llama 3.1 8B, Hermes 3, Qwen 3.5) | $0, no quota |
| **Cheap metered** | DeepSeek V4.1 Flash | ~$0.30/$1.20 per M |
| **Metered — avoid for lanes** | DeepSeek V4 Pro, `zai/glm-5.3`, `kimi-coding/k3`, OpenRouter frontier | $1.30–$10 in / up to $50 out per M |

**Metered-tier trap (verified 2026-10-16):** several `$0` models sit beside near-identical *paid* siblings with the same name, and the paid one is the obvious-looking choice — `kimi-coding/k3` ($3/$15) vs `k3-256k` (**$0**); `zai/glm-5.3` ($1.40/$4.40) vs `zai/glm-5.3-highspeed` (**$0**, same 1M ctx). Six research lanes were running on the paid Kimi tier for exactly this reason. **Check the `cost` field in `models-store.json` before assigning a lane.**

Copilot is **being retired** (2026-10-16) — no agent lane depends on it any more; the roster moved to OpenAI Codex (`$0` company subscription, quota-capped) and GLM-5.3-Highspeed (`$0`). If Copilot returns, treat it as an extra independent `$0` pool rather than a primary lane, since pool diversity is what prevents one quota exhaustion from halting everything.

## Final Agent↔Model Map

```
$0 — OpenAI Codex (company sub, quota) (6):
                                 architect, orchestrator, planner, reviewer,
                                 worker          [gpt-6.1-sol, 500K ctx]
                                 auditor         [gpt-6-astra, safety-critical]
$0 — GLM-5.3-Highspeed (z.ai, 1M ctx) (2):
                                 deep-scout, researcher
$0 — GLM-5.3-Highspeed (z.ai CN coding plan) (2):
                                 scout, docs-writer
$0 — Kimi K3-256K (256K ctx, 5h window) (1):
                                 db-analyst
$0 — local (1):                  fallback-worker  (Ollama Llama 3.1 8B)
Cheap metered (2):               quick-worker, router   (DeepSeek Flash $0.30/$1.20)
Budget metered (1):              enricher               (DeepSeek V4 Pro $1.32/$3.96)
Vision metered (1):              read-image             (Gemini 2.5 Flash)
```

**Provider-pool spread is deliberate.** Every `$0` lane sits in one of three *independent*
quota pools (OpenAI Codex, GLM-Highspeed, local). On 2026-10-16 a single kimi 5-hour quota
exhaustion took out six agents at once — recon, routing, DB analysis and docs simultaneously —
because all six shared one pool. Keep at least two pools live for any critical role, and note
that children do **not** inherit `model-tiers`' automatic quota fallback (that applies to the
main model only), so a subagent lane on an exhausted pool simply fails.

**Never put a lane on a metered tier when a `$0` sibling exists.** `kimi-coding/k3` is $3/$15 but
kimi's `$0` variant is `k3-256k`; `zai/glm-5.3` is $1.40/$4.40 but `zai/glm-5.3-highspeed` is
$0 with the same 1M context. As of 2026-10-16 no agent sits on a metered tier except the three
cheap lanes listed above.

## Routing Principles

1. **Don't use a sledgehammer for a nail** — simple tasks go to cheap models
2. **Security-sensitive = always the best model** — auditor/architect on Sonnet
3. **Research benefits from large context** — researcher/deep-scout on Kimi K3 (256K, subscription)
4. **Volume prose work goes to the cheapest capable lane** — transcript enrichment → `enricher` (DeepSeek V4 Pro). The risk there is fabrication, which is controlled by the agent's rules, not by paying for a frontier model.
5. **If unsure, ask the router** — `/route <task>` classifies and recommends

## Vault Integration

- `vault-lookup.py` at `/home/bgo/notes/bgovault/.scripts/vault-lookup.py`
- `learning-query.py` at `/home/bgo/notes/bgovault/.scripts/learning-query.py`
- Shared skills at `~/.claude/skills/` (30 of 40 work in Pi)

## Memory Bridge

Pi writes to `~/.claude/projects/<encoded-cwd>/memory/` — shared with Claude Code.
Both agents read from the same pool. Append-only.

## Capture Pipeline

Use `/capture <idea>` to drop ideas into Obsidian inbox for later sorting.
