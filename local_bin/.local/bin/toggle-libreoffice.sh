#!/bin/bash
# Toggle LibreOffice scratchpad window
# If not running, launch it; if running, toggle visibility

# Check if LibreOffice is running (Flatpak process name)
if pgrep -f "org.libreoffice.LibreOffice" > /dev/null; then
    # LibreOffice is running, toggle visibility via scratchpad
    # Also ensure proper size and centering each time we show it
    swaymsg '[con_mark="libreoffice"] scratchpad show' && \
    sleep 0.1 && \
    swaymsg '[con_mark="libreoffice"] resize set width 3200 px height 2000 px, move position center'
else
    # LibreOffice not running, launch it via Flatpak
    # Launch start center (user can choose which app to use)
    flatpak run org.libreoffice.LibreOffice &
fi
