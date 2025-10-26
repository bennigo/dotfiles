#!/bin/bash
# Toggle LibreOffice scratchpad window
# If not running, launch it; if running, toggle visibility

LOGFILE="/tmp/libreoffice-toggle.log"
echo "$(date): Script started" >> "$LOGFILE"

# Check if LibreOffice is running (look for soffice.bin)
if pgrep -x "soffice.bin" > /dev/null; then
    echo "$(date): LibreOffice is running, toggling" >> "$LOGFILE"
    # LibreOffice is running, toggle visibility via scratchpad
    # Also ensure proper size and centering each time we show it
    swaymsg '[con_mark="libreoffice"] scratchpad show' >> "$LOGFILE" 2>&1
    sleep 0.1
    swaymsg '[con_mark="libreoffice"] resize set width 3200 px height 2000 px, move position center' >> "$LOGFILE" 2>&1
    echo "$(date): Toggle complete" >> "$LOGFILE"
else
    echo "$(date): LibreOffice not running, launching" >> "$LOGFILE"
    # LibreOffice not running, launch it via Flatpak
    # Launch start center (user can choose which app to use)
    flatpak run org.libreoffice.LibreOffice >> "$LOGFILE" 2>&1 &
    echo "$(date): Launch initiated" >> "$LOGFILE"
fi
