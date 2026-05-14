# Pi Coding Agent Configuration

Minimal, customizable terminal AI coding agent — "primitives, not features" alternative
to Claude Code / Crush. Installed via npm (`@earendil-works/pi-coding-agent`), config
deployed via stow.

## Philosophy vs Crush / Claude Code

| | Claude Code | Crush | Pi |
|--|--|--|--|
| **Approach** | Sealed product | Sealed multi-provider TUI | Bring-your-own primitives |
| **MCP** | Native | Full parity | **None** (intentional) |
| **Extensibility** | Plugins/skills | Limited | Extensions (TS) + Skills + Packages |
| **Sessions** | Linear | Linear | **Tree-structured with branching** |
| **Claude Pro/Max OAuth** | Native | Via Copilot proxy | **Native `/login`** |

## XDG Compliance

Pi defaults to `~/.pi/agent/` which is non-XDG. We override via `PI_CODING_AGENT_DIR`
and `PI_CODING_AGENT_SESSION_DIR` env vars in `zsh/exports.zsh`:

| Concern | Default | Our override |
|---------|---------|--------------|
| Config | `~/.pi/agent/` | `~/.config/pi/agent/` |
| Sessions | inside config | `~/.local/share/pi/sessions/` |

## Provider Setup

Pi reads standard env vars; no separate provider config required for stock providers.

| Provider | Auth | Env var |
|----------|------|---------|
| **Anthropic (Claude Pro/Max)** | OAuth via `/login` | none (token stored by pi) |
| Anthropic API | API key | `ANTHROPIC_API_KEY` |
| OpenAI | API key | `OPENAI_API_KEY` |
| Google Gemini | API key | `GEMINI_API_KEY` |
| Kimi (Moonshot) | API key | `KIMI_API_KEY` or `MOONSHOT_API_KEY` |
| DeepSeek | API key | `DEEPSEEK_API_KEY` |
| Groq | API key | `GROQ_API_KEY` |
| OpenRouter | API key | `OPENROUTER_API_KEY` |
| xAI Grok | API key | `XAI_API_KEY` |
| Cerebras | API key | `CEREBRAS_API_KEY` |
| Bedrock | AWS creds | `AWS_*` |
| Ollama (local) | none | none |

For custom/exotic providers, add entries to `models.json` (not yet present).

## Shared Context

Pi auto-walks `CLAUDE.md` (or `AGENTS.md`) from:
1. `~/.config/pi/agent/AGENTS.md` (global, not present by default)
2. Parent directories (walking up from cwd)
3. Current directory

This is the **same hub-and-spoke pattern** that Claude Code and Crush use — no
duplication; existing `CLAUDE.md` hierarchy works as-is.

## Usage

```bash
pi                              # Interactive TUI (default provider: google)
pi --provider anthropic         # Override provider
pi -p "explain this file"       # Print mode (non-interactive)
pi --continue                   # Resume last session
pi --resume                     # Select session from picker
pi --mode json                  # JSON event stream output
pi config                       # TUI to enable/disable package resources
pi install npm:@foo/pi-tools    # Install a package
pi list                         # List installed extensions
# In TUI:
/login                          # OAuth for Claude Pro/Max etc.
/model     or Ctrl+L            # Switch model mid-session
Ctrl+P                          # Cycle favorite models
/tree                           # Navigate session branch tree
/export                         # Export session to HTML
/share                          # Upload session to GitHub gist
/reload                         # Reload customizations in-place
Enter                           # Send steering message (interrupts tools)
Alt+Enter                       # Send follow-up (waits for agent)
```

## Built-in Tools

`read`, `bash`, `edit`, `write` (on by default); `grep`, `find`, `ls` (read-only, off by default).

## Config Location

- Source: `.dotfiles/pi/.config/pi/agent/settings.json`
- Deployed: `~/.config/pi/agent/` (stow symlink, via `PI_CODING_AGENT_DIR`)
- Sessions: `~/.local/share/pi/sessions/` (via `PI_CODING_AGENT_SESSION_DIR`)
- Global binary: `~/.local/share/npm-global/bin/pi`

## Install / Update

```bash
npm install -g @earendil-works/pi-coding-agent       # initial install
pi update self                                       # update pi itself
pi update                                            # update installed extensions
```

## Skills

**Shared skill system** — Pi and Claude Code read skills from the same directory:

```
~/.claude/skills/          ← Single source of truth (40 skills)
├── vault-health/SKILL.md
├── jot/SKILL.md
├── floorit/SKILL.md
├── ...35 more...
└── excalidraw-skill/SKILL.md
```

| Agent | How it reads | Config |
|-------|-------------|--------|
| **Pi** | `settings.json` → `"skills": ["~/.claude/skills"]` | Auto-discover at startup |
| **Claude Code** | Auto-discovers `~/.claude/skills/*/SKILL.md` natively | None needed |

**Creating new skills** — create a directory in `~/.claude/skills/<name>/` with `SKILL.md` containing proper frontmatter (`name:` must match directory). Both agents pick it up on next start, no config changes required.

**Invoking skills in pi**: `/skill:name` (requires `enableSkillCommands: true` in settings.json, already set).

**Origin**: 39 of these were converted from Claude Code slash commands (`~/.claude/commands/`) on 2026-05-13. The originals still exist and work as `/command` invocations in Claude Code.

## Why No MCP?

Quoting Pi docs: *"No MCP. Build CLI tools with READMEs (see Skills), or build an extension
that adds MCP support."* Tradeoff: our 8 MCP servers (postgres-*, brave-search, fetch) are
unavailable in Pi out of the box. For database/search work, prefer Crush or Claude Code.
For pure coding, Pi's lean profile may be preferable.

## Cross-References

- **Shared skills**: `~/.claude/skills/` (also documented in `claude-code/CLAUDE.md`)

- **Crush config**: `crush/CLAUDE.md` (other multi-provider TUI)
- **Claude Code MCP config**: `claude-code/CLAUDE.md`
- **Shell env vars**: `zsh/.config/zsh/exports.zsh`

---

*Last reviewed: 2026-05-12*
