#!/usr/bin/env bash

#if it is running and player state is playing then
output=$(osascript -e '
tell application "Spotify"
  if it is running then
    set trackName to name of current track
    set artistName to artist of current track
    return trackName & " - " & artistName
  else
    return ""
  end if
end tell
')

sketchybar --set now_playing label="$output"
