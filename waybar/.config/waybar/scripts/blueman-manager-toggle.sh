#!/bin/bash
if pgrep "blueman-manager" > /dev/null; then
  echo "TEST"
  pkill blueman-manager
else
  blueman-manager &
fi

