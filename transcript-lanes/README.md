# transcript-lanes

The production runners behind the three transcript backfill services
(`diesen-backfill`, `neutrality-backfill`, `jfdw-backfill`).

**Why they live here.** They were previously *only* in `~/.cache/<lane>/`, which meant the
code that runs every daily transcript lane was one cache-wipe away from being lost, and
invisible to `git log`. `~/.cache/<lane>/` now holds the **state** (queues, catalogs,
checkpoints, logs, audio) plus a **symlink** to each script here, so
`ExecStart=%h/.cache/<lane>/resume.sh` still works unchanged.

| File | Role |
|---|---|
| `resume.sh` | Checkpointed Whisper queue; resumes at login. Has the `has_note()` dedup guard (skips videos already transcribed) and runs `yt-transcribe --link-audio` so SRT + audio persist to the vault's Assets rather than into the repo. |
| `postprocess.py` | Post-drain housekeeping: rename/whisper-fix notes, dedupe, drop stray `*.srt` from the output dir. |
| `digest-subs.py` | Subtitle digest helper. |
| `run-whisper2.sh` | Diesen lane's earlier batch runner (kept for reference). |

**Rule**: edit the files *here*. Editing `~/.cache/<lane>/resume.sh` now writes through the
symlink, which is the same file — but `git add` only sees this copy.
