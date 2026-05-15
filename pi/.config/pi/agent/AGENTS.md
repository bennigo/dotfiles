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

## Agent Roster (13 agents)

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
| **fallback-worker** | Qwen 3.5 (local) | 32K | Backup when cloud models rate-limited |

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
