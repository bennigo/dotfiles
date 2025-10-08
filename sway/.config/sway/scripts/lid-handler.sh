#!/usr/bin/env bash
#
# Power-Aware Lid Handler for Sway
#
# This script checks AC power status and performs different actions:
# - On AC power: Turn off screen only (keep system running)
# - On Battery: Full system suspend (save power)
#
# Usage:
#   lid-handler.sh close    # Called when lid closes
#   lid-handler.sh open     # Called when lid opens
#
# Sway bindings:
#   bindswitch --reload lid:on exec ~/.config/sway/scripts/lid-handler.sh close
#   bindswitch --reload lid:off exec ~/.config/sway/scripts/lid-handler.sh open

set -euo pipefail

# Configuration
LAPTOP_DISPLAY="eDP-1"
LOG_FILE="${XDG_RUNTIME_DIR:-/tmp}/sway-lid-handler.log"

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

# Check if running on AC power
is_on_ac_power() {
    # Method 1: Try acpi command (most reliable)
    if command -v acpi &>/dev/null; then
        acpi -a 2>/dev/null | grep -q "on-line" && return 0
    fi

    # Method 2: Check sysfs (fallback)
    if [[ -f /sys/class/power_supply/AC/online ]]; then
        [[ "$(cat /sys/class/power_supply/AC/online)" == "1" ]] && return 0
    fi

    # Method 3: Check other AC adapters
    for adapter in /sys/class/power_supply/AC*/online; do
        if [[ -f "$adapter" ]] && [[ "$(cat "$adapter")" == "1" ]]; then
            return 0
        fi
    done

    # Default to battery (safer - will suspend)
    return 1
}

# Handle lid close
handle_lid_close() {
    if is_on_ac_power; then
        log "Lid closed on AC power - turning off display only"
        # Turn off display but keep system running
        swaymsg output "$LAPTOP_DISPLAY" power off
        # Optional: Save brightness setting
        brightnessctl -s &>/dev/null || true
    else
        log "Lid closed on battery - suspending system"
        # Lock screen first
        swaylock -f -c 000000 -i "${XDG_CONFIG_HOME:-$HOME/.config}/sway/wallpapers/mahdi-khomsaz-asset.jpg" &
        # Brief delay to ensure lock screen appears
        sleep 0.5
        # Turn off display
        swaymsg output "$LAPTOP_DISPLAY" power off
        # Full system suspend
        systemctl suspend
    fi
}

# Handle lid open
handle_lid_open() {
    log "Lid opened - restoring display and brightness"
    # Turn display back on
    swaymsg output "$LAPTOP_DISPLAY" power on
    # Restore brightness
    brightnessctl -r &>/dev/null || brightnessctl set 50% &>/dev/null || true
}

# Main logic
case "${1:-}" in
    close)
        handle_lid_close
        ;;
    open)
        handle_lid_open
        ;;
    *)
        echo "Usage: $0 {close|open}"
        exit 1
        ;;
esac
