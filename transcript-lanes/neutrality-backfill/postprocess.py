#!/usr/bin/env python3
"""Post-process Diesen backfill transcripts.

- whisper notes (named <ts>-<vid>.md): rename to <ts>-<title-slug>.md, inject
  real title/date/URL/channel metadata from the episode list
- subs notes: add area: Geopolitics, dedupe consecutive duplicate caption lines
- drop stray .srt files
"""
import os
import re
import shutil
from pathlib import Path

VAULT = Path.home() / "notes/bgovault"
OUT = Path(os.environ.get("BB_OUT", "2.Areas/Geopolitics/transcripts/diesen-2026-backfill"))
if not OUT.is_absolute(): OUT = VAULT / OUT

# vid -> (date, title)
META = {}
for line in (Path(os.environ.get("BB_META", str(Path.home() / ".cache/diesen-backfill/diesen-all.txt")))).read_text().splitlines():
    d, vid, dur, title = line.split("|", 3)
    key = vid.lower().replace("_", "-").strip("-")
    META[key] = (d, title, int(dur), vid)

def slug(t):
    s = re.sub(r"[^a-z0-9]+", "-", t.lower()).strip("-")
    return "-".join(w for w in s.split("-") if w)[:70].rstrip("-")

n_renamed = n_deduped = 0
for f in sorted(OUT.glob("*.md")):
    text = f.read_text()
    # find video id: resource url or filename <ts>-<vid>
    m = re.search(r"watch\?v=([A-Za-z0-9_-]{11})", text)
    vid = m.group(1) if m else None
    if not vid:
        fm = re.search(r"(?:^|\n)id: \d{10}-([A-Za-z0-9_-]{8,})\n", text)
        fn = re.search(r"(\d{10})-([A-Za-z0-9_-]{8,})\.md$", f.name)
        vid = fm.group(1) if fm else (fn.group(2) if fn else None)
    if vid:
        vid = vid.lower().replace("_", "-").strip("-")
    if vid and vid in META:
        date, title, dur, meta_vid = META[vid]
        # strip old vid-based name
        old = text.split("---", 2)[1] if text.startswith("---") else ""
        aliases = title.replace('"', "'")
        new = text
        # frontmatter: fix aliases, resource, area
        new = re.sub(r"(?m)^aliases:\n(  - .*\n)+", f'aliases:\n  - "{aliases}"\n', new)
        new = re.sub(r"(?m)^resource: .*$", f'resource: "https://www.youtube.com/watch?v={meta_vid}"', new)
        new = re.sub(r"(?m)^area: .*$", "area: Geopolitics", new)
        # head: title + metadata
        if f.name.split("-", 1)[1].startswith(vid) or vid in f.name.split("-", 1)[1]:
            new = re.sub(r"(?m)^# .*\n", f"# {title}\n", new, count=1)
            # add channel/date block if missing
            if "**Channel**" not in new:
                new = new.replace("# " + title + "\n",
                    f"# {title}\n\n**Channel**: Neutrality Studies | **Date**: {date[:4]}-{date[4:6]}-{date[6:]} | **Duration**: {dur//60}:{dur%60:02d}\n", 1)
        # rename file
        if vid in f.name:
            dst = OUT / f"{f.stem.split('-')[0]}-{slug(title)}.md"
            f.write_text(new)
            f.rename(dst)
            n_renamed += 1
    else:
        # subs note with proper title: just set area + dedupe
        new = re.sub(r"(?m)^area: .*$", "area: Geopolitics", text)
        n_renamed += 0
        f.write_text(new)
        n_deduped += 1

# dedupe consecutive duplicate lines in subs transcripts
for f in OUT.glob("*.md"):
    t = f.read_text()
    if "[00:" not in t:
        continue
    lines = t.splitlines(keepends=True)
    out = []
    prev = None
    for ln in lines:
        # strip timestamp prefix for comparison
        core = re.sub(r"^\[?\d{2}:\d{2}:\d{2}\]?\s*", "", ln).strip()
        if core and core == prev:
            continue
        out.append(ln)
        prev = core
    f.write_text("".join(out))

# dedupe: for same-vid notes keep largest
from collections import defaultdict
groups = defaultdict(list)
for f in OUT.glob("*.md"):
    m = re.match(r"^(\d{10})-([a-z0-9_-]{5,})\.md$", f.name)
    if m: groups[m.group(2)].append(f)
for v, fs in groups.items():
    if len(fs) > 1:
        for f in sorted(fs, key=lambda x: x.stat().st_size, reverse=True)[1:]:
            f.unlink(); print("dedup removed:", f.name)

# align frontmatter id with filename (vault convention)
for f in OUT.glob("*.md"):
    if f.name.startswith("1788264200"):
        continue
    head = f.read_text()[:400]
    m = re.search(r"(?m)^id: ([^\n]+)$", head)
    if m and m.group(1) != f.stem:
        t2 = f.read_text()
        f.write_text(re.sub(r"(?m)^id: [^\n]+$", f"id: {f.stem}", t2, count=1))

for srt in OUT.glob("*.srt"):
    srt.unlink()

print(f"renamed/whisper-fixed: {n_renamed} · touched others: {n_deduped} · srt cleaned")
