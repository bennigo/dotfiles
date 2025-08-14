#!/bin/bash

cwd="${HOME}/notes/bgovault"
echo "${cwd}"
# Check if an argument is provided
if [ $# -eq 0 ]; then
  :
elif [ -z "$1" ]; then
  echo "Usage: $0 [new|today|quick|normal|template]"
  exit 1
fi

# Start zsh and run the appropriate Neovim command based on the argument
if [[ $# -eq 0 || $1 == "normal" ]]; then
  nvim
elif [ "$1" = "quick" ]; then
  nvim -c ":cd ${cwd}" -c ":ObsidianQuickSwitch"
elif [ "$1" = "today" ]; then
  nvim -c ":cd ${cwd}" -c ":ObsidianToday"
elif [ "$1" = "new" ]; then
  nvim -c ":cd ${cwd}" -c ":ObsidianNew"
elif [ "$1" = "template" ]; then
  nvim -c ":cd ${cwd}" -c ":ObsidianNewFromTemplate"
else
  echo "Invalid argument: $1"
  echo "Usage: $0 [new|today|quick|normal|template]"
  exit 1
fi
