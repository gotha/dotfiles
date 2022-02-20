#!/usr/bin/env bash

setxkbmap -option caps:escape

setxkbmap -layout us,bg
setxkbmap -option 'grp:win_space_toggle'

# to see current settings 'xset -q'
# xset r rate 660 25 # default <repeat delay>/<repeat rate>
xset r rate 400 80

