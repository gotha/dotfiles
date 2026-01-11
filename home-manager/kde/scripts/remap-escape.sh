#!/usr/bin/env bash
# Remap Escape key to Tilde/Grave (matching Sway configuration)

# Wait for X server to be ready
sleep 2

# Use xmodmap to remap Escape (keycode 9) to grave/tilde
xmodmap -e "keycode 9 = grave asciitilde grave asciitilde"

