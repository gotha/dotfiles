#!/usr/bin/env bash

WALLPAPER_DIR="$HOME/Pictures/wallpapers"

if [ ! -d "$WALLPAPER_DIR" ]; then
    echo "Wallpaper directory does not exist: $WALLPAPER_DIR"
    exit 1
fi
random_wallpaper=$(find $WALLPAPER_DIR -type f | shuf -n 1)

# Set the wallpaper using swaybg
swaymsg output "*" bg "$random_wallpaper" fill

echo "Wallpaper changed to: $random_wallpaper"
