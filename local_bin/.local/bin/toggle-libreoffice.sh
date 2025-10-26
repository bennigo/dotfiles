#!/bin/bash
# Toggle LibreOffice scratchpad window
# If not running, launch it; if running, toggle visibility

# Check if LibreOffice is running
if pgrep -x "soffice.bin" > /dev/null; then
    # LibreOffice is running, toggle visibility via scratchpad
    swaymsg '[con_mark="libreoffice"] scratchpad show'
else
    # LibreOffice not running, launch it
    # Use Writer by default, but you can change to --calc or --impress
    gtk-launch org.libreoffice.LibreOffice.writer.desktop
fi
