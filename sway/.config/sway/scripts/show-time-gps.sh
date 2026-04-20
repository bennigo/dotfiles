#!/usr/bin/env bash
# Toast the current time, date, GPS week and day-of-year as a centered
# large-font overlay (via notify-send + Mako's sway-overlay rule).
#
# Usage:
#   show-time-gps.sh [-t SECONDS]
#
# Options:
#   -t, --timeout SECONDS   How long the toast stays on screen (default: 5)
#
# The notification uses app-name=sway-overlay, which triggers the matching
# block in the mako config (centered anchor, large HackNerdFont, silent).
# Repeated invocations replace the previous toast via the synchronous hint.

set -euo pipefail

TIMEOUT_SEC=5

while [[ $# -gt 0 ]]; do
  case "$1" in
    -t|--timeout)
      [[ $# -ge 2 ]] || { echo "error: --timeout needs a value" >&2; exit 2; }
      TIMEOUT_SEC="$2"
      shift 2
      ;;
    -h|--help)
      sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

if ! [[ "$TIMEOUT_SEC" =~ ^[0-9]+$ ]]; then
  echo "error: timeout must be a non-negative integer (got: $TIMEOUT_SEC)" >&2
  exit 2
fi

TIMEOUT_MS=$(( TIMEOUT_SEC * 1000 ))

read -r TIME DATE ISOWK GPSWK DOY < <(python3 - <<'PY'
from datetime import datetime, timezone
local = datetime.now()
utc = datetime.now(timezone.utc)
gps_epoch = datetime(1980, 1, 6, tzinfo=timezone.utc)
gps_week = int((utc - gps_epoch).total_seconds() // 604800)
iso_week = local.isocalendar().week
doy = local.timetuple().tm_yday
print(local.strftime("%H:%M:%S"),
      local.strftime("%Y-%m-%d"),
      iso_week, gps_week, doy)
PY
)

notify-send \
  -a sway-overlay \
  -t "$TIMEOUT_MS" \
  -h "string:x-canonical-private-synchronous:time-gps" \
  "🕒 ${TIME}   📅 ${DATE}" \
  "<span size=\"150%\">Wk ${ISOWK}   •   GPS ${GPSWK}   •   DOY ${DOY}</span>"
