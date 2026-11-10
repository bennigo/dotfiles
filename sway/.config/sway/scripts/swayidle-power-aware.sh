#!/usr/bin/env bash
#
# Power-Aware swayidle Launcher for Sway
#
# This script launches swayidle with different timeout behaviors based on AC power:
# - On AC: Dim → Lock → Screen off (but keep system running)
# - On Battery: Dim → Lock → Screen off → Suspend (to save power)
#
# The script dynamically adjusts by checking power status before critical actions.
#
# Usage:
#   Called from Sway config: exec_always ~/.config/sway/scripts/swayidle-power-aware.sh

set -euo pipefail

# Configuration
LAPTOP_DISPLAY="eDP-1"
WALLPAPER="${XDG_CONFIG_HOME:-$HOME/.config}/sway/wallpapers/mahdi-khomsaz-asset.jpg"
LOG_FILE="${XDG_RUNTIME_DIR:-/tmp}/swayidle-power-aware.log"
# Set by the Waybar keep-awake toggle: only lock + screens off after 30 min
KEEP_AWAKE="${XDG_RUNTIME_DIR:-/tmp}/keep-awake"

# Timeouts (in seconds)
TIMEOUT_DIM=60           # Dim screen after 1 minute
TIMEOUT_LOCK=300         # Lock screen after 5 minutes
TIMEOUT_SCREEN_OFF=900   # Turn off screen after 15 minutes
TIMEOUT_SUSPEND=1800     # Suspend on battery after 30 minutes total idle

# Logging
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

# Check if on AC power
is_on_ac_power() {
    if command -v acpi &>/dev/null; then
        acpi -a 2>/dev/null | grep -q "on-line" && return 0
    fi

    if [[ -f /sys/class/power_supply/AC/online ]]; then
        [[ "$(cat /sys/class/power_supply/AC/online)" == "1" ]] && return 0
    fi

    for adapter in /sys/class/power_supply/AC*/online; do
        if [[ -f "$adapter" ]] && [[ "$(cat "$adapter")" == "1" ]]; then
            return 0
        fi
    done

    return 1
}

# Conditional suspend - only if on battery
conditional_suspend() {
    if [[ -e "$KEEP_AWAKE" ]]; then
        log "Keep-awake on - locking and turning screens off only"
        pgrep -x swaylock >/dev/null || swaylock -f -c 000000 -i "$WALLPAPER"
        swaymsg 'output * power off'
    elif is_on_ac_power; then
        log "Would suspend, but on AC power - skipping"
    else
        log "On battery power - executing system suspend"
        systemctl suspend-then-hibernate
    fi
}

# Handle --suspend-check flag (called by swayidle timeout)
if [[ "${1:-}" == "--suspend-check" ]]; then
    conditional_suspend
    exit 0
fi

log "Starting power-aware swayidle"

# Kill any existing swayidle instances
pkill -f "swayidle -w" || true
sleep 0.5

# Launch swayidle with power-aware configuration
exec swayidle -w \
    timeout $TIMEOUT_DIM "[ -e $KEEP_AWAKE ] || { brightnessctl -s; brightnessctl set 10%; }" \
        resume "[ -e $KEEP_AWAKE ] || brightnessctl -r" \
    timeout $TIMEOUT_LOCK "[ -e $KEEP_AWAKE ] || swaylock -f -c 000000 -i $WALLPAPER" \
    timeout $TIMEOUT_SCREEN_OFF "[ -e $KEEP_AWAKE ] || swaymsg output $LAPTOP_DISPLAY power off" \
        resume "swaymsg output $LAPTOP_DISPLAY power on" \
    timeout $TIMEOUT_SUSPEND "$0 --suspend-check" \
        resume "[ -e $KEEP_AWAKE ] && swaymsg 'output * power on'" \
    before-sleep "swaylock -f -c 000000 -i $WALLPAPER; swaymsg 'output * power off'" \
    after-resume "swaymsg output $LAPTOP_DISPLAY power on; brightnessctl -r"
