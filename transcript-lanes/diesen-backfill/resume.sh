#!/bin/bash
# Diesen backfill — checkpointed Whisper queue (reboot-resilient)
set -u
cd /home/bgo/notes/bgovault
OUT="2.Areas/Geopolitics/transcripts/diesen-2026-backfill"
AUDIO="$HOME/.cache/diesen-backfill/audio"
mkdir -p "$AUDIO"
LOG="$HOME/.cache/diesen-backfill/whisper.log"
YT="uv run --with yt-dlp yt-dlp"

has_note() {
  # A video is "done" if ANY transcript note references it — by raw id (the
  # "Source file" path keeps the original case), by normalized id (postprocess
  # rewrites URLs to lower/kebab), or by a vid-named whisper note. The old
  # check only matched "watch?v=<raw>", which missed postprocessed notes AND
  # ids containing '_', so completed episodes were re-transcribed with --force.
  local vid="$1" norm
  norm="$(printf '%s' "$vid" | tr 'A-Z' 'a-z' | tr '_' '-')"
  norm="${norm#-}"
  ls "$OUT" | grep -qiE "^[0-9]{10}-${norm}\.md$" && return 0
  grep -rilq --exclude='*highlights*' -e "$vid" -e "$norm" "$OUT"/*.md 2>/dev/null && return 0
  return 1
}

for url in $(cat "$HOME/.cache/diesen-backfill/whisper-queue.txt"); do
  [ -z "$url" ] && continue
  vid="${url##*=}"
  has_note "$vid" && { echo "$(date +%H:%M) SKIP $vid (done)"; continue; }
  echo "$(date +%H:%M) START $vid"
  sl="${vid,,}"; sl="${sl//_/-}"
  ok=0
  for attempt in 1 2 3; do
    if $YT --cookies-from-browser chrome -f "ba[ext=m4a]/ba" -x --audio-format mp3 -o "$AUDIO/%(id)s.%(ext)s" "$url" >/dev/null 2>&1; then
      ok=1; break
    fi
    echo "$(date +%H:%M) DL-retry $vid ($attempt)"; sleep 60
  done
  if [ "$ok" != "1" ]; then
    echo "$(date +%H:%M) DL-FAIL-permanent $vid — exiting for service restart"; exit 1
  fi
  timeout 3000 ~/.local/bin/yt-transcribe -m large-v3 --force --link-audio -f vault -o "$OUT" "$url" --file "$AUDIO/$vid.mp3" </dev/null >/dev/null 2>&1
  stubs=0
  for f in "$OUT"/*${sl}*.md; do
    [ -f "$f" ] || continue
    s=$(stat -c%s "$f" 2>/dev/null || echo 0)
    if [ "$s" -lt 15000 ]; then rm -f "$f"; stubs=$((stubs+1)); fi
  done
  if [ "$stubs" -gt 0 ]; then
    echo "$(date +%H:%M) STUB-DETECTED $vid ($stubs files) — retry later"; rm -f "$OUT"/*${sl}*.srt; rm -f "$AUDIO/$vid.mp3"; exit 1
  fi
  echo "$(date +%H:%M) DONE $vid"; rm -f "$AUDIO/$vid.mp3" 
  sleep 3
done

# queue fully drained → post-process + enrichment + notify
python3 "$HOME/.cache/diesen-backfill/postprocess.py" >> "$LOG" 2>&1
python3 "$HOME/notes/bgovault/.scripts/morning-enrich/enrich-transcripts.py" "$OUT" >> "$LOG" 2>&1
python3 "$HOME/notes/bgovault/.scripts/morning-enrich/add-placeholders.py" "$OUT" >> "$LOG" 2>&1
notify-send "🎧 Diesen backfill" "Queue complete + post-processed + enriched" 2>/dev/null || true
exit 0
