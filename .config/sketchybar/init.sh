#!/bin/bash

# ---------------- INITIALIZATION ----------------
# The config file initializes sketchybar and is run before all other scripts

# Set the config directory
PLUGIN_DIR="$HOME/.config/sketchybar/plugins"

# Load colors
source "$HOME/.config/sketchybar/colors.sh"

# Unload any running instances of sketchybar
sketchybar --remove '/.*/'

# General bar appearance
sketchybar --bar height=42 \
                 position=top \
                 padding_left=10 \
                 padding_right=10 \
                 color=$BAR_COLOR \
                 corner_radius=0 \
                 y_offset=0 \
                 margin=0 \
                 notch_width=200 \
                 display=main

# Default values for all further items
sketchybar --default updates=when_shown \
                     drawing=on \
                     icon.font="SF Pro:Bold:14.0" \
                     icon.color=$ICON_COLOR \
                     label.font="SF Pro:Semibold:13.0" \
                     label.color=$LABEL_COLOR \
                     icon.padding_left=5 \
                     icon.padding_right=5 \
                     label.padding_left=5 \
                     label.padding_right=5

# ---------------- LEFT ITEMS ----------------

# Active application display
sketchybar --add item front_app left \
           --set front_app script="$PLUGIN_DIR/front_app.sh" \
                          icon.drawing=off \
                          background.padding_left=0 \
                          background.padding_right=0 \
           --subscribe front_app front_app_switched

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
                        script="$PLUGIN_DIR/battery.sh" \
                        background.height=26 \
                        background.color=$TRANSPARENT \
                        background.corner_radius=9 \
                        background.padding_right=5 \
                        label.drawing=off \
                        icon.padding_right=2 \
                        icon.padding_left=10

# Volume level
sketchybar --add item volume right \
           --set volume script="$PLUGIN_DIR/volume.sh" \
                      icon.color=$BLUE \
                      update_freq=2 \
                      background.height=26 \
                      background.color=$TRANSPARENT \
                      background.corner_radius=9 \
                      background.padding_right=5 \
           --subscribe volume volume_change

# ---------------- FINALIZING ----------------
# Force all scripts to run the first time
sketchybar --update

echo "sketchybar configuration loaded.."

