#!/usr/bin/env bash

# MPD now playing widget
# Uses mpc to get current track info

MPC="@mpc@/bin/mpc"

# Check if MPD is running and get current track
if $MPC status &>/dev/null; then
  state=$($MPC status | sed -n '2p' | awk '{print $1}' | tr -d '[]')

  if [ "$state" = "playing" ] || [ "$state" = "paused" ]; then
    # Get current song info (format: artist - title)
    current=$($MPC current -f "%artist% - %title%")

    # If no artist/title metadata, fall back to filename
    if [ "$current" = " - " ] || [ -z "$current" ]; then
      current=$($MPC current -f "%file%")
      # Strip path and extension
      current=$(basename "$current" | sed 's/\.[^.]*$//')
    fi

    # Add play/pause indicator
    if [ "$state" = "playing" ]; then
      icon="▶"
    else
      icon="⏸"
    fi

    output="$icon $current"
  else
    output=""
  fi
else
  output=""
fi

sketchybar --set now_playing label="$output"
