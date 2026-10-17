#!/usr/bin/env python3
"""
Keep the roster's derived copies in sync with `agents/*.md`.

WHY (2026-10-17, pipeline architecture review, Phase 4): the agent roster is
encoded in more than one place, and the extra copies drifted repeatedly.

    agents/*.md                        <- SOURCE OF TRUTH
    extensions/model-discovery.ts      <- AGENT_MODELS (display)
    AGENTS.md                          <- documentation tables

On 2026-10-16 the model-discovery copy was found still listing `github-copilot`
models after the whole roster had moved to OpenAI Codex, AND it was missing
`enricher` entirely — invisible, because nothing failed. The display simply
omitted a lane.

This script makes the code copy derived. `--check` is suitable for a pre-commit
hook or a cron check; `--write` regenerates it.

AGENTS.md is documentation and is NOT regenerated here: its tables carry prose
rationale per row. Treat it as prose that must be reviewed, and rely on this
script for the machine-read copy.

Usage
    sync-roster.py --check     # exit 1 if model-discovery.ts differs from agents/*.md
    sync-roster.py --write     # rewrite AGENT_MODELS from agents/*.md
    sync-roster.py --show      # print the agent→model map
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

AGENT_DIR = Path(__file__).resolve().parent.parent
AGENTS = AGENT_DIR / "agents"
TARGET = AGENT_DIR / "extensions" / "model-discovery.ts"

BLOCK_START = "const AGENT_MODELS: AgentModelMap[] = ["
BLOCK_END = "];"


def read_agents() -> dict[str, str]:
    """name -> model, from agent frontmatter. Source of truth."""
    out: dict[str, str] = {}
    for f in sorted(AGENTS.glob("*.md")):
        text = f.read_text(errors="replace")
        m = re.search(r"^model:\s*(.+?)\s*$", text, re.MULTILINE)
        if not m:
            print(f"  warning: {f.name} declares no model", file=sys.stderr)
            continue
        out[f.stem] = m.group(1)
    return out


def read_derived() -> dict[str, str]:
    """name -> model, parsed from model-discovery.ts."""
    if not TARGET.exists():
        return {}
    text = TARGET.read_text(errors="replace")
    start = text.find(BLOCK_START)
    if start == -1:
        return {}
    end = text.find(BLOCK_END, start)
    block = text[start:end]
    return {
        m.group(1): m.group(2)
        for m in re.finditer(r'\{\s*agent:\s*"([^"]+)",\s*model:\s*"([^"]+)"\s*\}', block)
    }


def render_block(agents: dict[str, str]) -> str:
    lines = [
        "const AGENT_MODELS: AgentModelMap[] = [",
        "  // GENERATED from agents/*.md by scripts/sync-roster.py --write.",
        "  // Do not hand-edit: run the script instead, or drift returns silently.",
    ]
    for name in sorted(agents):
        lines.append(f'  {{ agent: "{name}", model: "{agents[name]}" }},')
    lines.append("];")
    return "\n".join(lines)


def main() -> int:
    ap = argparse.ArgumentParser(description="Sync the derived roster copy")
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument("--check", action="store_true", help="exit 1 on drift")
    g.add_argument("--write", action="store_true", help="regenerate the derived copy")
    g.add_argument("--show", action="store_true", help="print the source map")
    args = ap.parse_args()

    agents = read_agents()
    if not agents:
        print("no agents found — is agents/ present?", file=sys.stderr)
        return 2

    if args.show:
        for name, model in sorted(agents.items()):
            print(f"  {name:20s} {model}")
        return 0

    derived = read_derived()

    if args.write:
        text = TARGET.read_text(errors="replace")
        start = text.find(BLOCK_START)
        end = text.find(BLOCK_END, start)
        if start == -1 or end == -1:
            print(f"could not locate AGENT_MODELS in {TARGET}", file=sys.stderr)
            return 2
        end += len(BLOCK_END)
        TARGET.write_text(text[:start] + render_block(agents) + text[end:])
        print(f"rewrote AGENT_MODELS in {TARGET.name} ({len(agents)} agents)")
        return 0

    # --check
    problems: list[str] = []
    for name in sorted(set(agents) | set(derived)):
        a, d = agents.get(name), derived.get(name)
        if a is None:
            problems.append(f"{name}: in model-discovery.ts but NOT an agent file")
        elif d is None:
            problems.append(f"{name}: agent exists but MISSING from model-discovery.ts")
        elif a != d:
            problems.append(f"{name}: agents={a}  discovery={d}")

    if problems:
        print(f"ROSTER DRIFT ({len(problems)}):")
        for p in problems:
            print(f"  {p}")
        print("\nFix with: scripts/sync-roster.py --write")
        return 1

    print(f"roster in sync — {len(agents)} agents")
    return 0


if __name__ == "__main__":
    sys.exit(main())
