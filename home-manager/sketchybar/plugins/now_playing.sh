#!/usr/bin/env bash

# Now Playing widget for sketchybar
# Shows currently playing media from any source (browser, Spotify, Music, MPD, etc.)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/now_playing_helper.sh"

# Ensure NAME is set for sketchybar
: "${NAME:=now_playing}"

# Try nowplaying-cli first (browsers, Spotify, Music app, etc.)
if info=$(get_nowplaying_info); then
  IFS='|' read -r state artist title <<< "$info"
  output=$(format_output "$state" "$artist" "$title")
  sketchybar --set "$NAME" label="$output"
  exit 0
fi

# Fallback to MPD
if info=$(get_mpd_info); then
  IFS='|' read -r state artist title <<< "$info"
  output=$(format_output "$state" "$artist" "$title")
  sketchybar --set "$NAME" label="$output"
  exit 0
fi

# Nothing playing
sketchybar --set "$NAME" label=""
