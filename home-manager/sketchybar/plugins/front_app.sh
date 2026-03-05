#!/bin/bash

# Get the current app name and icon
FRONT_APP=$(osascript -e 'tell application "System Events" to set frontApp to name of first application process whose frontmost is true')

# Map Nix-wrapped app names to friendly names
case "$FRONT_APP" in
  ".kitty-wrapped") FRONT_APP="Kitty" ;;
  ".alacritty-wrapped") FRONT_APP="Alacritty" ;;
  ".firefox-wrapped") FRONT_APP="Firefox" ;;
  "firefox") FRONT_APP="Firefox" ;;
esac

# Check if the app name is available
if [[ $FRONT_APP != "" ]]; then
  sketchybar --set $NAME label="$FRONT_APP"
else
  sketchybar --set $NAME label="Desktop"
fi
