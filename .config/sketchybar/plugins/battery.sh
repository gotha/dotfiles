#!/bin/bash

# Get battery information
PERCENTAGE=$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)
CHARGING=$(pmset -g batt | grep 'AC Power')

# Set the right icon based on charging state and percentage
if [[ $CHARGING != "" ]]; then
  ICON=""
  ICON_COLOR="0xffa6e3a1" # Green when charging
else
  case ${PERCENTAGE} in
    100) ICON="🔋" ;;
    9[0-9]) ICON="🔋" ;;
    8[0-9]) ICON="🔋" ;;
    7[0-9]) ICON="🔋" ;;
    6[0-9]) ICON="🔋" ;;
    5[0-9]) ICON="🔋" ;;
    4[0-9]) ICON="🔋" ;;
    3[0-9]) ICON="🔋" ;;
    2[0-9]) ICON="🪫" ;;
    1[0-9]) ICON="🪫" ;;
    *) ICON="🔋"
  esac
  
  # Change color based on battery level
  if [[ ${PERCENTAGE} -le 10 ]]; then
    ICON_COLOR="0xfff38ba8" # Red when very low
  elif [[ ${PERCENTAGE} -le 30 ]]; then
    ICON_COLOR="0xfff9e2af" # Yellow when low
  else
    ICON_COLOR="0xffa6e3a1" # Green when good
  fi
fi

# Update the battery item with icon and percentage
sketchybar --set $NAME icon=$ICON icon.color=$ICON_COLOR label="${PERCENTAGE}%"
