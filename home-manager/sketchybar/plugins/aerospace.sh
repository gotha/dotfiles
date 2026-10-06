#!/usr/bin/env bash

# Hide workspaces with no windows, highlight the focused one, label each with
# the apps on it. Match SPACE_COUNT to sketchybarrc.
SPACE_COUNT=10

# Defines __icon_map, which sets icon_result to a ligature the app font draws
# as a glyph. Sourced rather than run so a window does not cost a fork.
source "@sketchybar-app-font@/bin/icon_map.sh"

FOCUSED="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused)}"

declare -A seen icons
while IFS='|' read -r ws app; do
  [ -n "$ws" ] || continue
  [ -n "${seen[$ws:$app]:-}" ] && continue
  seen[$ws:$app]=1
  __icon_map "$app"
  icons[$ws]="${icons[$ws]:+${icons[$ws]} }$icon_result"
done < <(aerospace list-windows --all --format '%{workspace}|%{app-name}')

args=()
for sid in $(seq 1 $SPACE_COUNT); do
  label="${icons[$sid]:-}"
  if [ "$sid" = "$FOCUSED" ]; then
    args+=(--set "space.$sid" drawing=on background.drawing=on label="$label")
  elif [ -n "$label" ]; then
    args+=(--set "space.$sid" drawing=on background.drawing=off label="$label")
  else
    args+=(--set "space.$sid" drawing=off background.drawing=off label="")
  fi
done

sketchybar "${args[@]}"
