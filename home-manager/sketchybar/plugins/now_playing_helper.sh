#!/usr/bin/env bash

# Shared helper functions for now_playing widgets
# Sources: nowplaying-cli (Homebrew) for browser/app media, MPD for local music

# Detect nowplaying-cli path (ARM Mac vs Intel Mac)
if [ -x "/opt/homebrew/bin/nowplaying-cli" ]; then
  NOWPLAYING_CLI="/opt/homebrew/bin/nowplaying-cli"
elif [ -x "/usr/local/bin/nowplaying-cli" ]; then
  NOWPLAYING_CLI="/usr/local/bin/nowplaying-cli"
else
  NOWPLAYING_CLI=""
fi

MPC="@mpc@/bin/mpc"
MAX_LENGTH=50

# Truncate string to max length with ellipsis
truncate_string() {
  local str="$1"
  local max="$2"
  if [ ${#str} -gt $max ]; then
    echo "${str:0:$((max-3))}..."
  else
    echo "$str"
  fi
}

# Get the currently active player
# Returns: "nowplaying", "mpd", or "none"
get_active_player() {
  if [ -n "$NOWPLAYING_CLI" ] && [ -x "$NOWPLAYING_CLI" ]; then
    local state=$("$NOWPLAYING_CLI" get playbackRate 2>/dev/null)
    if [ "$state" = "1" ] || [ "$state" = "0" ]; then
      echo "nowplaying"
      return
    fi
  fi

  if [ -x "$MPC" ] && $MPC status &>/dev/null; then
    local mpd_state=$($MPC status | sed -n '2p' | awk '{print $1}' | tr -d '[]')
    if [ "$mpd_state" = "playing" ] || [ "$mpd_state" = "paused" ]; then
      echo "mpd"
      return
    fi
  fi

  echo "none"
}

# Get now playing info from nowplaying-cli
# Returns: "state|artist|title" (state is "playing" or "paused")
get_nowplaying_info() {
  if [ -z "$NOWPLAYING_CLI" ] || [ ! -x "$NOWPLAYING_CLI" ]; then
    return 1
  fi

  local rate=$("$NOWPLAYING_CLI" get playbackRate 2>/dev/null)
  local state=""
  
  if [ "$rate" = "1" ]; then
    state="playing"
  elif [ "$rate" = "0" ]; then
    state="paused"
  else
    return 1
  fi

  local artist=$("$NOWPLAYING_CLI" get artist 2>/dev/null)
  local title=$("$NOWPLAYING_CLI" get title 2>/dev/null)

  # Clean up null values
  [ "$artist" = "null" ] && artist=""
  [ "$title" = "null" ] && title=""

  if [ -n "$title" ]; then
    echo "${state}|${artist}|${title}"
    return 0
  fi

  return 1
}

# Get now playing info from MPD
# Returns: "state|artist|title" (state is "playing" or "paused")
get_mpd_info() {
  if [ ! -x "$MPC" ] || ! $MPC status &>/dev/null; then
    return 1
  fi

  local state=$($MPC status | sed -n '2p' | awk '{print $1}' | tr -d '[]')
  
  if [ "$state" != "playing" ] && [ "$state" != "paused" ]; then
    return 1
  fi

  local current=$($MPC current -f "%artist%|%title%")
  
  # If no metadata, fall back to filename
  if [ "$current" = "|" ] || [ -z "$current" ]; then
    local filename=$($MPC current -f "%file%")
    filename=$(basename "$filename" | sed 's/\.[^.]*$//')
    current="|${filename}"
  fi

  echo "${state}|${current}"
  return 0
}

# Control playback for the active player
# Args: action (toggle, next, prev)
control_playback() {
  local action="$1"
  local player=$(get_active_player)

  case "$player" in
    "nowplaying")
      case "$action" in
        "toggle") "$NOWPLAYING_CLI" togglePlayPause ;;
        "next") "$NOWPLAYING_CLI" next ;;
        "prev") "$NOWPLAYING_CLI" previous ;;
      esac
      ;;
    "mpd")
      case "$action" in
        "toggle") "$MPC" toggle ;;
        "next") "$MPC" next ;;
        "prev") "$MPC" prev ;;
      esac
      ;;
  esac
}

# Format output for sketchybar
# Args: state, artist, title
format_output() {
  local state="$1"
  local artist="$2"
  local title="$3"
  local icon=""

  if [ "$state" = "playing" ]; then
    icon="▶"
  else
    icon="⏸"
  fi

  if [ -n "$artist" ]; then
    echo "$icon $(truncate_string "$artist - $title" $MAX_LENGTH)"
  else
    echo "$icon $(truncate_string "$title" $MAX_LENGTH)"
  fi
}
