#!/usr/bin/env python3
"""Digest subs notes: extract claim-bearing lines per episode for future enrichment."""
import re
from pathlib import Path

OUT = Path.home() / "notes/bgovault/2.Areas/Geopolitics/transcripts/diesen-2026-backfill"
DIG = Path.home() / ".cache/diesen-backfill/subs-digests"
DIG.mkdir(exist_ok=True)

# claim-bearing patterns: numbers, money, dates, %s, hard verbs
PAT = re.compile(
    r"\$\s?\d|per\s?cent|%\s|million|billion|trillion|thousand|\b\d{2,4}\b|sanction|blockade|"
    r"nuclear|missile|drone|warhead|tonnage|barrel|tanker|invade|withdraw|ceasefire|"
    r"Oman|Hormuz|Taiwan|NATO|Article 5|rare earth|interceptor|air defense", re.I)

for f in sorted(OUT.glob("*.md")):
    d = DIG / (f.stem + ".digest")
    if d.exists():  # idempotent
        continue
    lines = [l for l in f.read_text(errors="ignore").splitlines()
             if PAT.search(l) and len(l.strip()) > 40]
    if not lines:
        continue
    # dedupe near-identical consecutive, cap at 60 lines
    out, prev = [], None
    for l in lines:
        core = re.sub(r"^\[\d{2}:\d{2}:\d{2}\]\s*", "", l).strip()
        if core and core != prev:
            out.append(l); prev = core
    d.write_text("\n".join(out[:60]))
print("digests done:", len(list(DIG.glob('*.digest'))))
