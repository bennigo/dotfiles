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

## Model Optimization Framework

The agent system is designed to route tasks to the optimal LLM based on capability match:

- **Expensive/capable models** (Copilot Sonnet 4.6, Kimi K2.5): complex reasoning, security, architecture
- **Cheap/fast models** (DeepSeek V3, Kimi K2 Turbo): scouting, simple changes, documentation
- **Free/local models** (Qwen 3.5, DeepSeek Coder V2 via Ollama): fallback when cloud is rate-limited

Adding a new model: edit `models.json` (live-reloads via `/model`), then optionally create an agent that uses it.

## Agent Roster (12 agents)

### Exploration & Analysis

| Agent | Model | Context | Use for |
|-------|-------|---------|---------|
| **scout** | DeepSeek V3 | 64K | Fast recon, small-medium codebases |
| **deep-scout** | Kimi K2.5 | 256K | Multi-file analysis, large codebases, cross-cutting traces |
| **researcher** | Kimi K2.5 | 256K | Web research, source synthesis, tech evaluation |
| **db-analyst** | Claude Sonnet 4.6 | 200K | SQL queries, schema analysis, data exploration |

### Design & Planning

| Agent | Model | Context | Use for |
|-------|-------|---------|---------|
| **architect** | Claude Sonnet 4.6 | 200K | High-level design, tradeoff analysis, tech selection |
| **planner** | Claude Sonnet 4.6 | 200K | Implementation plans from findings (existing) |

### Implementation

| Agent | Model | Context | Use for |
|-------|-------|---------|---------|
| **worker** | Claude Sonnet 4.6 | 200K | Complex implementation, multi-step refactors (existing) |
| **quick-worker** | DeepSeek V3 | 64K | Boilerplate, simple changes, config updates |
| **fallback-worker** | Qwen 3.5 (local) | 32K | Backup when cloud models rate-limited |

### Quality

| Agent | Model | Context | Use for |
|-------|-------|---------|---------|
| **reviewer** | Claude Sonnet 4.6 | 200K | Code review, style, basic correctness (existing) |
| **auditor** | Claude Sonnet 4.6 | 200K | Security audit, vulnerability analysis, threat modeling |

### Meta

| Agent | Model | Context | Use for |
|-------|-------|---------|---------|
| **router** | DeepSeek V3 | 64K | Task classification — recommends optimal agent/workflow |
| **docs-writer** | DeepSeek V3 | 64K | READMEs, API docs, changelogs, code comments |

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
| **Premium** | Claude Sonnet 4.6 (Copilot) | Subscription |
| **Mid** | Kimi K2.5 | ~$2.60/M tokens (in+out) |
| **Budget** | DeepSeek V3, Kimi K2 Turbo | ~$0.30-$1.30/M tokens |
| **Free** | Ollama local models (Qwen, DeepSeek Coder) | $0 |

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
