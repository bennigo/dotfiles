#!/bin/bash

export GRIM_DEFAULT_DIR="${HOME}/Pictures/Screenshots"
export GRIM_DEFAULT_QUALITY=90

# Ensure the directory exists
mkdir -p "$GRIM_DEFAULT_DIR"

# Function to take a screenshot with a custom filename
take_screenshot() {
  local filename
  filename="screenshot-$(date +%Y%m%d-%H%M%S).png"
  grim "$GRIM_DEFAULT_DIR/$filename"
}
