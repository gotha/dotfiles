#!/bin/bash

# ---------------- INITIALIZATION ----------------
# The config file initializes sketchybar and is run before all other scripts

# Set the config directory
CONFIG_DIR="$HOME/.config/sketchybar"
PLUGIN_DIR="$CONFIG_DIR/plugins"

# Load colors
source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/icons.sh"

FONT="Hack Nerd Font" # Needs to have Regular, Bold, Semibold, Heavy and Black variants
PADDINGS=3 # All paddings use this value (icon, label, background)

# aerospace setting
AEROSPACE_FOCUSED_MONITOR_NO=$(aerospace list-workspaces --focused)
AEROSPACE_LIST_OF_WINDOWS_IN_FOCUSED_MONITOR=$(aerospace list-windows --workspace $AEROSPACE_FOCUSED_MONITOR_NO | awk -F'|' '{gsub(/^ *| *$/, "", $2); print $2}')


# Unload any running instances of sketchybar
sketchybar --remove '/.*/'

# General bar appearance
sketchybar --bar height=42 \
                 position=top \
                 padding_left=20 \
                 padding_right=20 \
                 color=$BAR_COLOR \
                 corner_radius=0 \
                 y_offset=0 \
                 margin=0 \
                 notch_width=200 \
                 font_smoothing=on \
                 blur_radius=10 \
                 display=all

# Default values for all further items
sketchybar --default updates=when_shown \
                     drawing=on \
                     icon.font="$FONT:Bold:14.0" \
                     icon.color=$ICON_COLOR \
                     label.font="$FONT:Semibold:13.0" \
                     label.color=$LABEL_COLOR \
                     icon.padding_left=5 \
                     icon.padding_right=5 \
                     label.padding_left=5 \
                     label.padding_right=5

# ---------------- LEFT ITEMS ----------------
#
sketchybar --add event aerospace_workspace_change

#for sid in $(aerospace list-workspaces --all); do
#  echo $sid
#  if [ $sid -gt 10 ]; then
#    # I want to see only the first 10 spaces
#    continue
#  fi

# temporarily switching to hardcoded workspaces
for sid in {1..10}; do
  LABEL="${sid}"

  sketchybar --add item space.$sid left \
      --subscribe space.$sid aerospace_workspace_change \
      --set space.$sid \
      icon.font="$FONT:Bolder:14.0" \
      icon.color=$ICON_COLOR \
      background.color=0x44ffffff \
      background.corner_radius=3 \
      background.height=20 \
      background.drawing=off \
      label="$LABEL" \
      click_script="aerospace workspace $sid" \
      script="$CONFIG_DIR/plugins/aerospace.sh $sid"

done

# Active application display
sketchybar --add item front_app left \
           --set front_app script="$PLUGIN_DIR/front_app.sh" \
                          icon.drawing=off \
                          background.padding_left=10 \
                          background.padding_right=10 \
           --subscribe front_app front_app_switched


sketchybar --add item now_playing left \
           --set now_playing label="" \
                             update_freq=5 \
                             script="$PLUGIN_DIR/spotify.sh" \
                             click_script="osascript -e 'tell application \"Spotify\" to playpause'"
                             #padding_left=420

# ---------------- RIGHT ITEMS ----------------


# clock
sketchybar --add item clock right \
           --set clock update_freq=10 \
                      script="$PLUGIN_DIR/clock.sh" \
                      background.color=$TRANSPARENT \
                      background.height=26 \
                      background.corner_radius=9

# Battery indicator
sketchybar --add item battery right \
           --set battery update_freq=120 \
                        script="$PLUGIN_DIR/battery.sh"

# Volume level
sketchybar --add item volume right \
           --set volume script="$PLUGIN_DIR/volume.sh" \
                      icon.color=$BLUE \
                      update_freq=2 \
           --subscribe volume volume_change


sketchybar --add item input_source right
sketchybar --set input_source \
    icon.font="$FONT:Regular:20.0" \
    script="$PLUGIN_DIR/get_input_source.sh" \
    icon.color=0xffffffff \
    update_freq=1

# ---------------- FINALIZING ----------------

sketchybar --hotload on
# Force all scripts to run the first time
sketchybar --update


echo "sketchybar configuration loaded.."

