#!/bin/bash

# Get the current volume
VOLUME=$(osascript -e 'output volume of (get volume settings)')
MUTED=$(osascript -e 'output muted of (get volume settings)')

# Set icon based on volume level and mute status
if [[ $MUTED == "true" ]]; then
  ICON=""
  ICON_COLOR="0xff6c7086" # Gray when muted
else
  case ${VOLUME} in
    100) ICON="" ;;
    [6-9][0-9]) ICON="" ;;
    [3-5][0-9]) ICON="" ;;
    [1-2][0-9]) ICON="" ;;
    *) ICON="" ;;
  esac
  ICON_COLOR="0xff89b4fa" # Blue when not muted
fi

# Update the volume item
#sketchybar --set $NAME icon=$ICON icon.color=$ICON_COLOR label="${VOLUME}%"
sketchybar --set $NAME icon=$ICON icon.color=$ICON_COLOR
