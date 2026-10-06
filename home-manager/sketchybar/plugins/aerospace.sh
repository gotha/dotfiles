#!/usr/bin/env bash

# Hide workspaces with no windows, highlight the focused one. Match sketchybarrc.
SPACE_COUNT=10

FOCUSED="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused)}"
OCCUPIED=$(aerospace list-workspaces --monitor all --empty no)

args=()
for sid in $(seq 1 $SPACE_COUNT); do
  if [ "$sid" = "$FOCUSED" ]; then
    args+=(--set "space.$sid" drawing=on background.drawing=on)
  elif grep -qxF "$sid" <<<"$OCCUPIED"; then
    args+=(--set "space.$sid" drawing=on background.drawing=off)
  else
    args+=(--set "space.$sid" drawing=off background.drawing=off)
  fi
done

sketchybar "${args[@]}"
