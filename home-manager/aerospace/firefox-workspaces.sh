# Remember assignments across watcher restarts, but forget closed Firefox windows.
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/aerospace"
state_file="$state_dir/firefox-workspaces.json"
umask 077
mkdir -p "$state_dir"
assigned_windows='[]'
if [[ -f "$state_file" ]]; then
  assigned_windows=$(jq -c '.' "$state_file")
fi

save_state() {
  local state_tmp
  state_tmp=$(mktemp "$state_dir/.firefox-workspaces.XXXXXX")
  printf '%s\n' "$assigned_windows" > "$state_tmp"
  mv -f "$state_tmp" "$state_file"
}

# Wait for names to appear, then assign each window only once.
sync_windows() {
  local windows live_assignments assignments window_id workspace current_workspace key

  # AeroSpace may not be ready at login or may itself be restarting.
  if ! windows=$(aerospace list-windows --all \
    --format '%{window-id} %{app-pid} %{app-bundle-id} %{workspace} %{window-title}' \
    --json 2>/dev/null); then
    return 0
  fi

  # Include the process ID so a Firefox restart starts fresh even if IDs repeat.
  live_assignments=$(jq -c --argjson assigned "$assigned_windows" '
    [.[] | select(."app-bundle-id" == "org.mozilla.firefox")
      | "\(."app-pid"):\(."window-id")"] as $live
    | $assigned | map(select(. as $key | $live | index($key)))
  ' <<< "$windows")
  if [[ "$live_assignments" != "$assigned_windows" ]]; then
    assigned_windows="$live_assignments"
    save_state
  fi

  assignments=$(jq -r --argjson assigned "$assigned_windows" '
    .[]
    | select(."app-bundle-id" == "org.mozilla.firefox")
    | . as $window
    | "\(."app-pid"):\(."window-id")" as $key
    | select(($assigned | index($key)) == null)
    | (."window-title" | capture("\\bff:aerospace:ws(?<target>[123])\\b"))
    | [$window."window-id", .target, $window.workspace, $key]
    | @tsv
  ' <<< "$windows")

  while IFS=$'\t' read -r window_id workspace current_workspace key; do
    [[ -n "$window_id" ]] || continue

    if [[ "$current_workspace" != "$workspace" ]]; then
      # Retry next time if the window closed or AeroSpace became unavailable.
      if ! aerospace move-node-to-workspace --window-id "$window_id" "$workspace"; then
        continue
      fi
      printf 'Assigned Firefox window %s to workspace %s\n' "$window_id" "$workspace"
    fi

    # Already-correct windows count as assigned too. Later manual moves stay put.
    assigned_windows=$(jq -c --arg key "$key" '. + [$key]' <<< "$assigned_windows")
    save_state
  done <<< "$assignments"
}

if [[ "${1:-}" == "--once" ]]; then
  sync_windows
else
  while true; do
    sync_windows
    sleep 2
  done
fi
