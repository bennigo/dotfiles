#!/bin/bash
if pgrep "blueman-manager" > /dev/null; then
  pkill blueman-manager
else
  swaymsg exec blueman-manager &
fi

