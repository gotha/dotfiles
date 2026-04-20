#!/usr/bin/env bash

# Click handler for now_playing widget
# Left click: toggle play/pause
# Right click: next track
# Middle click: previous track

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/now_playing_helper.sh"

# Handle click based on button
# BUTTON values: left, right, center
case "$BUTTON" in
  "left")
    control_playback "toggle"
    ;;
  "right")
    control_playback "next"
    ;;
  "center")
    control_playback "prev"
    ;;
esac

# Trigger an update of the widget
sleep 0.1  # Brief delay to let the player state update
sketchybar --update
