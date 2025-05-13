#!/bin/bash

# Get the current date and time
DATE=$(date '+%a %b %d')
TIME=$(date '+%I:%M %p')

# Set the clock item with date and time
sketchybar --set $NAME label="$DATE  $TIME"
