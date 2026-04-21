#!/usr/bin/env bash
# Toast the current xkb layout as a centered large-font overlay (via the
# mako sway-overlay rule). By default this also cycles to the next layout,
# but with --show-only it leaves the layout unchanged — useful when the
# actual switching is handled at the xkb level (grp:toggle on Caps-Lock).
#
# Usage:
#   show-layout.sh [--show-only] [--restore] [-t SECONDS]
#
# Options:
#   --show-only         Display the current layout without switching.
#   --restore           Undo one xkb group-toggle cycle before displaying.
#                       Useful when this script is invoked from a bindsym
#                       that contains Alt Gr (xkb will have cycled the
#                       layout before sway fired the binding, so we need
#                       to step back one to reveal the *actual* current
#                       layout). Implies --show-only.
#   -t, --timeout S     Overlay duration in seconds (default: 0.5).
#                       Accepts fractional values, e.g. 0.5 or 1.2.

set -euo pipefail

SHOW_ONLY=0
RESTORE=0
TIMEOUT_SEC=0.5

while [[ $# -gt 0 ]]; do
  case "$1" in
    --show-only) SHOW_ONLY=1; shift ;;
    --restore)   RESTORE=1; SHOW_ONLY=1; shift ;;
    -t|--timeout)
      [[ $# -ge 2 ]] || { echo "error: --timeout needs a value" >&2; exit 2; }
      TIMEOUT_SEC="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *)
      echo "error: unknown argument: $1" >&2; exit 2 ;;
  esac
done

if ! [[ "$TIMEOUT_SEC" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
  echo "error: timeout must be a non-negative number (integer or decimal)" >&2
  exit 2
fi

TIMEOUT_MS=$(awk -v t="$TIMEOUT_SEC" 'BEGIN { printf "%d", (t * 1000) + 0.5 }')

if (( RESTORE == 1 )); then
  # xkb has already cycled the layout (because this script was fired from a
  # bindsym that contains Alt Gr, which grp:toggle consumes). Step back one
  # position to undo that cycle before we read/display the "current" layout.
  read -r CUR_IDX TOTAL < <(
    swaymsg -r -t get_inputs \
      | jq -r '[.[] | select(.type=="keyboard" and ((.xkb_layout_names // [])|length)>1)][0]
              | "\(.xkb_active_layout_index) \(.xkb_layout_names|length)"'
  ) || true
  if [[ "${CUR_IDX:-}" =~ ^[0-9]+$ ]] && [[ "${TOTAL:-}" =~ ^[0-9]+$ ]] && (( TOTAL > 1 )); then
    PREV=$(( (CUR_IDX - 1 + TOTAL) % TOTAL ))
    swaymsg "input type:keyboard xkb_switch_layout $PREV" >/dev/null
  fi
elif (( SHOW_ONLY == 0 )); then
  swaymsg 'input type:keyboard xkb_switch_layout next' >/dev/null
fi

layout="$(
  swaymsg -r -t get_inputs \
    | jq -r '[.[] | select(.type=="keyboard" and .xkb_active_layout_name)
                  | .xkb_active_layout_name] | first // "?"'
)"

# Build a short two/three-letter tag. sway reports descriptive names
# ("English (US)", "Icelandic") but not the xkb code (us/is), so map the
# layouts actually in use here and fall back to the parenthesised variant
# or the first two letters of the language.
case "$layout" in
  "English (US)")                 short="US" ;;
  "English (UK)"|"English (GB)")  short="GB" ;;
  "Icelandic")                    short="IS" ;;
  "German"|"German ("*)           short="DE" ;;
  *)
    paren_re='\(([^)]+)\)'
    if [[ "$layout" =~ $paren_re ]]; then
      short="${BASH_REMATCH[1]^^}"
    else
      short="$(printf '%s' "$layout" | awk '{print toupper(substr($1,1,2))}')"
    fi
    ;;
esac
[[ -z "$short" ]] && short="??"

notify-send \
  -a sway-layout \
  -t "$TIMEOUT_MS" \
  -h "string:x-canonical-private-synchronous:kbd-layout" \
  "⌨️  ${short}" \
  "${layout}"
