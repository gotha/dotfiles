#!/bin/bash

# Get the current app name and icon
FRONT_APP=$(osascript -e 'tell application "System Events" to set frontApp to name of first application process whose frontmost is true')

# Check if the app name is available
if [[ $FRONT_APP != "" ]]; then
  sketchybar --set $NAME label="$FRONT_APP"
else
  sketchybar --set $NAME label="Desktop"
fi
