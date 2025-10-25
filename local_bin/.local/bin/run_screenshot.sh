#!/bin/bash
# Check if an argument is provided

# to have the option on none standart config and station file input
options="[fullscreen|window|region]"
screenshot_program="${HOME}/.local/bin/sway-screenshot"
mode="fullscreen" # default value

SCREENSHOT_DEFAULT_DIR=$HOME/Pictures/Screenshots

GRIM_DEFAULT_DIR="${GRIM_DEFAULT_DIR:-$SCREENSHOT_DEFAULT_DIR}"
GRIM_DEFAULT_QUALITY="${GRIM_DEFAULT_QUALITY:-90}"
mkdir -p -- "$GRIM_DEFAULT_DIR"

SWAY_SCREENSHOT_DIR="${SWAY_SCREENSHOT_DIR:-$SCREENSHOT_DEFAULT_DIR}"

function take_screenshot() {
  # Function to take a screenshot with a custom filename
  local filename
  filename="screenshot-$(date +%Y%m%d-%H%M%S).png"
  grim "$GRIM_DEFAULT_DIR/$filename"
}

function Help() {
  cat <<EOF
Usage: run-screenshot.sh [options ..] -m [mode] 

A utility running sway-screenshot

Options:
  -h    show help message and exit
  -m    one of: fullscreen, window, region
  -s    don't send notification when screenshot is saved
  -c    copy screenshot to clipboard and don't save image on disk
  -e    open screenshot with swappy -f

Modes:
  fullscreen            take screenshot of an entire monitor
  window                take screenshot of an open window
  region                take screenshot of selected region
EOF
}

while getopts "hecsm:" flag; do
  case "${flag}" in
  h)
    Help
    exit 0
    ;;
  m)
    mode=${OPTARG}
    ;;
  s)
    silent="-s"
    ;;
  e)
    cmd="swappy -f"
    ;;
  c)
    clip="--clipboard-only"
    ;;
  *)
    echo "Invalid option: -${OPTARG}" >&2
    Help
    exit 1
    ;;
  esac
done
# Remove flag options from $@
shift "$((OPTIND - 1))"

if [ $# -eq 0 ]; then
  :
elif [ -z "$1" ]; then
  echo "Usage: $1 ${options}"
  exit 1
fi

if [ "${mode}" = "fullscreen" ]; then
  if [ -n "${clip}" ]; then
    grim - | wl-copy
    if [ -n "${cmd}" ]; then
      wl-paste | ${cmd} -
    fi
  else
    take_screenshot
  fi

elif [[ $mode =~ ^(window|region)$ ]]; then
  if [ -z "${cmd}" ]; then
    :
  else
    cmd="-- "${cmd}
    if [ -n "${clip}" ]; then
      cmd=${cmd}" -"
    fi

  fi
  "${screenshot_program}" ${silent} ${clip} -m ${mode} ${cmd}
else
  echo "Invalid argument: $1"
  echo "Usage: $0 ${options}"
  exit 1
fi
