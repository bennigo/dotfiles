#!/bin/bash
# Check if an argument is provided

# to have the option on none standart config and station file input
options="[fullscreen|window|region]"
screenshot_program="${HOME}/.local/bin/sway-screenshot"
mode="fullscreen" # default value

function Help() {
  cat <<EOF
Usage: run-screenshot.sh [options ..] -m [mode] 

A utility running sway-screenshot

Options:
  -h    show help message and exit
  -m    one of: fullscreen, window, region
  -s    don't send notification when screenshot is saved
  -c    copy screenshot to clipboard and don't save image in disk
  -e    open screenshot with swappy -f

Modes:
  fullscreen            take screenshot of an entire monitor
  window                take screenshot of an open window
  region                take screenshot of selected region
EOF
}

while getopts hecsm: flag; do
  case "${flag}" in
  h)
    Help
    exit
    ;;
  m)
    mode=${OPTARG}
    ;;
  s)
    silent="-s"
    ;;
  e)
    cmd="${HOME}/.local/bin/swappy -f"
    ;;
  c)
    clip="--clipboard-only"
    ;;
  esac
done
# remove flag options from $@
shift $((OPTIND - 1))

if [ $# -eq 0 ]; then
  :
elif [ -z "$1" ]; then
  echo "Usage: $1 ${options}"
  exit 1
fi

# Start zsh and run the appropriate Neovim command based on the argument
if [ "${mode}" = "fullscreen" ]; then
  grim - | wl-copy
  if [ -z "${cmd}" ]; then
    :
  else
    ${HOME}/.local/bin/clipse -p | ${cmd} -
  fi

elif [[ $mode =~ ^(window|region)$ ]]; then
  if [ -z "${cmd}" ]; then
    :
  else
    cmd="-- "$cmd
  fi
  "${screenshot_program}" ${silent} ${clip} -m ${mode} ${cmd}
else
  echo "Invalid argument: $1"
  echo "Usage: $0 ${options}"
  exit 1
fi
