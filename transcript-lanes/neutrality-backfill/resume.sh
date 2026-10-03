#!/bin/bash
# Diesen backfill — checkpointed Whisper queue (reboot-resilient)
set -u
cd /home/bgo/notes/bgovault
OUT="${BB_OUT:-2.Areas/Geopolitics/transcripts/diesen-2026-backfill}"
AUDIO="${BB_AUDIO:-$HOME/.cache/diesen-backfill/audio}"
mkdir -p "$AUDIO"
LOG="${BB_LOG:-$HOME/.cache/diesen-backfill/whisper.log}"
YT="uv run --with yt-dlp yt-dlp"

has_note() {
  local vid="$1" lvid="${1,,}" sl="${1,,}"
  sl="${sl//_/-}"
  ls "$OUT" | grep -qiE "^[0-9]{10}-${sl}\.md$" && return 0
  grep -il "watch?v=$vid" "$OUT"/*.md >/dev/null 2>&1 && return 0
  return 1
}

QUEUE="${BB_QUEUE:-$HOME/.cache/diesen-backfill/whisper-queue.txt}"
for url in $(cat "$QUEUE"); do
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

# queue fully drained → post-process + notify
META="${BB_META:-$HOME/.cache/diesen-backfill/diesen-all.txt}"
BB_META="$META" BB_OUT="$OUT" python3 "$HOME/.cache/neutrality-backfill/postprocess.py" >> "$LOG" 2>&1
notify-send "🎧 Diesen backfill" "Queue complete + post-processed" 2>/dev/null || true
exit 0
