#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )


FF_CONFIG_DIR=$([[ "$OSTYPE" =~ darwin  ]] && echo "$HOME/Library/Application Support/Firefox" || echo "$HOME/.mozilla/firefox")

if [ ! -f "$FF_CONFIG_DIR/profiles.ini" ]; then
  echo "unable to find profiles.ini in $FF_CONFIG_DIR"
  exit 1
fi

PROFILE_PATH_REL=$(cat "$FF_CONFIG_DIR/profiles.ini" | grep -E -i 'Path.*default-release' | awk -F\= '{print $2}')
PROFILE_PATH="$FF_CONFIG_DIR/$PROFILE_PATH_REL"
if [ ! -d "$PROFILE_PATH" ]; then
  echo "unable to determine profile config dir; $PROFILE_PATH does not exist"
  exit 1
fi

if [ -f "$PROFILE_PATH/user.js" ]; then
  echo "aborting! user.js already exists in $PROFILE_PATH"
  exit 1
fi

ln -s "$SCRIPT_DIR/user.js" "$PROFILE_PATH/user.js"
ln -s "$SCRIPT_DIR/chrome" "$PROFILE_PATH/chrome"

echo "Done"
