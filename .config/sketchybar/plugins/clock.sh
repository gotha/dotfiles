#!/bin/bash

# Get the current date and time
DATE=$(date '+%a %d %b')
TIME=$(date '+%I:%M')

# Set the clock item with date and time
sketchybar --set $NAME \
      icon.font="$FONT:Bold:14.0" \
      icon.color=$ICON_COLOR \
      label="$DATE  $TIME"
