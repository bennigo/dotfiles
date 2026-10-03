#!/bin/bash
cd /home/bgo/notes/bgovault
OUT="2.Areas/Geopolitics/transcripts/diesen-2026-backfill"
AUDIO="/tmp/diesen-audio"
mkdir -p "$AUDIO"
YT="uv run --with yt-dlp yt-dlp"
while IFS='|' read -r url title; do
  [ -z "$url" ] && continue
  vid="${url##*=}"
  echo "=== $(date +%H:%M) [whisper] $title"
  # 1. download audio with cookies
  if ! $YT --cookies-from-browser chrome -f "ba[ext=m4a]/ba" -x --audio-format mp3 -o "$AUDIO/%(id)s.%(ext)s" "$url" >/dev/null 2>&1; then
    echo "  DOWNLOAD FAILED: $url"; continue
  fi
  # 2. whisper
  timeout 3000 ~/.local/bin/yt-transcribe -m large-v3 --force -f vault -o "$OUT" "$url" --file "$AUDIO/$vid.mp3" </dev/null >/dev/null 2>&1 || { echo "  WHISPER FAILED: $url"; }
  # 3. cleanup intermediates (metadata post-pass runs after queue)
  rm -f "$AUDIO/$vid.mp3"
  sleep 2
done < /home/bgo/.cache/diesen-backfill/diesen-whisper.txt
echo "WHISPER2 DONE $(date)"
