#!/bin/bash
if pgrep "ronema" > /dev/null; then
  pkill ronema 
else
  swaymsg exec ~/.local/bin/ronema &
fi
