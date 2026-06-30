# Speech-to-text dictation using whisper.cpp
# Usage: dictate (records audio, transcribes with whisper, types result)
{
  config,
  pkgs,
  lib,
  username,
  ...
}:

with lib;

let
  cfg = config.services.dictation;

  # The whisper binary to use
  whisperBin = "${cfg.whisperPackage}/bin/whisper-cli";
  whisperServerBin = "${cfg.whisperPackage}/bin/whisper-server";

  serverUrl = "http://${cfg.server.host}:${toString cfg.server.port}";

  # Absolute model path for the system service ($HOME is not expanded in ExecStart).
  serverModelFile = "${
    config.users.users.${username}.home
  }/.local/share/whisper/ggml-${cfg.model}.bin";

  # Transcription step. Sets $RESULT to the trimmed transcription, or exits 1.
  # Server mode posts the wav to the always-on whisper-server (model stays
  # resident in VRAM); otherwise a one-shot whisper-cli loads the model each run.
  transcribe =
    if cfg.server.enable then
      ''
        echo "Transcribing (server)..."

        WHISPER_OUTPUT=$(mktemp /tmp/whisper-output-XXXXXX.txt)
        WHISPER_ERROR=$(mktemp /tmp/whisper-error-XXXXXX.txt)

        HTTP_CODE=$(${pkgs.curl}/bin/curl -s -o "$WHISPER_OUTPUT" -w "%{http_code}" \
          --max-time 60 \
          -F file=@"$TEMP_WAV" \
          -F temperature=0 \
          -F response_format=text \
          "${serverUrl}/inference" 2>"$WHISPER_ERROR") || true

        if [[ "$HTTP_CODE" != "200" ]]; then
          echo "ERROR: whisper-server request failed (HTTP ''${HTTP_CODE:-none})!"
          echo "Is it running?  systemctl status whisper-server"
          echo ""
          cat "$WHISPER_ERROR" "$WHISPER_OUTPUT" 2>/dev/null || true
          rm -f "$WHISPER_OUTPUT" "$WHISPER_ERROR"
          exit 1
        fi

        RESULT=$(tr -d '\n' < "$WHISPER_OUTPUT" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        rm -f "$WHISPER_OUTPUT" "$WHISPER_ERROR"
      ''
    else
      ''
        echo "Transcribing..."

        # Run whisper and capture both stdout and stderr
        WHISPER_OUTPUT=$(mktemp /tmp/whisper-output-XXXXXX.txt)
        WHISPER_ERROR=$(mktemp /tmp/whisper-error-XXXXXX.txt)

        if ! ${whisperBin} \
          -m "$WHISPER_MODEL" \
          -f "$TEMP_WAV" \
          -nt \
          >"$WHISPER_OUTPUT" 2>"$WHISPER_ERROR"; then

          echo "ERROR: Whisper transcription failed!"
          echo ""
          cat "$WHISPER_ERROR"

          rm -f "$WHISPER_OUTPUT" "$WHISPER_ERROR"
          exit 1
        fi

        RESULT=$(grep -v "^\[" "$WHISPER_OUTPUT" | tr -d '\n' | sed 's/^[[:space:]]*//')
        rm -f "$WHISPER_OUTPUT" "$WHISPER_ERROR"
      '';

  # While recording we "duck" any currently-playing audio so it neither drowns
  # out the speaker nor leaks into the mic. Two strategies, selected by
  # cfg.pauseMusic:
  #   - default:    save the system volume and lower it to 10%, restoring after.
  #   - pauseMusic: toggle playback via waybar-mpris (if a player is playing)
  #                 and toggle it back after.
  # duckStart runs in dictate-hotkey; duckStop runs in dictate once recording
  # finishes or is cancelled. Each undoes only what it did.
  duckStart =
    if cfg.pauseMusic then
      ''
        # waybar-mpris only offers a toggle, so gate it on the play state from
        # `--send list`: toggle (pause) only if something is currently playing,
        # recording that we did so duckStop only resumes what we paused.
        # --autofocus makes the toggle target the playing player.
        if ${pkgs.waybar-mpris}/bin/waybar-mpris --send list 2>/dev/null | grep -q "Playing: true"; then
          ${pkgs.waybar-mpris}/bin/waybar-mpris --send toggle || true
          touch /tmp/dictate-paused-music
        fi
      ''
    else
      ''
        # Save current volume and lower to 10% during dictation.
        ${pkgs.pamixer}/bin/pamixer --get-volume > /tmp/dictate-original-volume
        ${pkgs.pamixer}/bin/pamixer --set-volume 10
      '';

  duckStop =
    if cfg.pauseMusic then
      ''
        # Resume (toggle back) playback only if we paused it.
        if [[ -f /tmp/dictate-paused-music ]]; then
          ${pkgs.waybar-mpris}/bin/waybar-mpris --send toggle || true
          rm -f /tmp/dictate-paused-music
        fi
      ''
    else
      ''
        # Restore the original volume if it was lowered.
        if [[ -f /tmp/dictate-original-volume ]]; then
          ORIGINAL_VOL=$(cat /tmp/dictate-original-volume)
          ${pkgs.pamixer}/bin/pamixer --set-volume "$ORIGINAL_VOL"
          rm -f /tmp/dictate-original-volume
        fi
      '';

  # Dictation script using whisper.cpp
  dictate = pkgs.writeShellScriptBin "dictate" ''
    set -euo pipefail

    DEFAULT_MODEL="${cfg.model}"
    DEFAULT_MODEL_PATH="${cfg.modelPath}"
    WHISPER_MODEL="''${WHISPER_MODEL:-$DEFAULT_MODEL_PATH}"
    TEMP_WAV=$(mktemp /tmp/dictation-XXXXXX.wav)

    cleanup() {
      rm -f "$TEMP_WAV"
    }
    trap cleanup EXIT

    # Check if model exists, offer to download if not
    if [[ ! -f "$WHISPER_MODEL" ]]; then
      echo "Whisper model not found at: $WHISPER_MODEL"
      echo ""
      read -p "Would you like to download the '$DEFAULT_MODEL' model? [y/N] " -n 1 -r
      echo ""

      if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Downloading $DEFAULT_MODEL model..."
        ${dictate-download-model}/bin/dictate-download-model "$DEFAULT_MODEL"
        echo ""
        echo "Model downloaded. Starting dictation..."
        echo ""
      else
        echo "Aborted. You can manually download with: dictate-download-model $DEFAULT_MODEL"
        exit 1
      fi
    fi

    echo "Recording... Press Enter to stop, Escape to cancel"

    # Record audio using sox with a time limit trick for graceful stop
    # We'll record to a temp file and use SIGINT for proper buffer flushing
    ${pkgs.sox}/bin/rec -q -r 16000 -c 1 "$TEMP_WAV" &
    RECORD_PID=$!

    # Wait for Enter or Escape key
    while true; do
      read -r -s -n 1 key
      if [[ "$key" == "" ]]; then
        # Enter was pressed
        break
      elif [[ "$key" == $'\e' ]]; then
        # Escape was pressed - cancel recording
        echo "Cancelled"
        kill -INT $RECORD_PID 2>/dev/null || true
        wait $RECORD_PID 2>/dev/null || true

        # Undo audio ducking on cancel
        ${duckStop}

        exit 1
      fi
    done

    # Keep recording for 1.5 more seconds to capture end of sentence
    echo "Finishing..."
    sleep 1.5

    # Use SIGINT (like Ctrl+C) for graceful shutdown with buffer flush
    kill -INT $RECORD_PID 2>/dev/null || true
    wait $RECORD_PID 2>/dev/null || true

    # Ensure file is fully written
    sync
    sleep 0.3

    # Undo audio ducking after recording stops (for dictate-hotkey)
    ${duckStop}

    ${transcribe}

    if [[ -n "$RESULT" ]]; then
      echo "$RESULT"

      # Copy to clipboard (Wayland)
      echo -n "$RESULT" | ${pkgs.wl-clipboard}/bin/wl-copy
      echo "(copied to clipboard)"
    else
      echo "No speech detected"
      exit 1
    fi
  '';

  # Script to download whisper model
  dictate-download-model = pkgs.writeShellScriptBin "dictate-download-model" ''
    set -euo pipefail

    MODEL_DIR="$HOME/.local/share/whisper"
    mkdir -p "$MODEL_DIR"

    # Available models: tiny, base, small, medium, large, large-v3
    MODEL="''${1:-base}"

    # Map model names to full filenames
    case "$MODEL" in
      tiny)    FILE="ggml-tiny.bin" ;;
      base)    FILE="ggml-base.bin" ;;
      small)   FILE="ggml-small.bin" ;;
      medium)  FILE="ggml-medium.bin" ;;
      large)   FILE="ggml-large-v3.bin" ;;
      large-v3) FILE="ggml-large-v3.bin" ;;
      *)       FILE="ggml-$MODEL.bin" ;;
    esac

    OUTPUT="$MODEL_DIR/ggml-$MODEL.bin"

    echo "Downloading whisper model: $MODEL ($FILE)"
    echo "This may take a while for larger models..."

    ${pkgs.curl}/bin/curl -L --progress-bar -o "$OUTPUT" \
      "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/$FILE"

    # Verify the download
    SIZE=$(stat -c%s "$OUTPUT" 2>/dev/null || echo 0)
    if [[ "$SIZE" -lt 1000000 ]]; then
      echo "ERROR: Download failed or file too small ($SIZE bytes)"
      echo "Contents: $(cat "$OUTPUT")"
      rm -f "$OUTPUT"
      exit 1
    fi

    echo "Model downloaded to: $OUTPUT ($SIZE bytes)"
    echo "Set WHISPER_MODEL env var or use default (base)"
  '';

  # Wrapper script that runs dictate and handles errors
  dictate-wrapper = pkgs.writeShellScriptBin "dictate-wrapper" ''
    # Run dictate (volume restore happens inside dictate after recording stops)
    ${dictate}/bin/dictate
    EXIT_CODE=$?

    if [[ $EXIT_CODE -eq 0 ]]; then
      # Success - signal to hotkey script to paste by creating a temp file
      touch /tmp/dictate-success
    else
      # Error - wait for keypress before closing
      echo ""
      echo "Press any key to close..."
      read -n 1 -s
    fi
  '';

  # Hotkey script for global shortcut
  # Ducks currently-playing audio (lowers volume or pauses playback), opens a
  # floating terminal for dictation, then restores audio after.
  dictate-hotkey = pkgs.writeShellScriptBin "dictate-hotkey" ''
    # Clean up any previous success marker
    rm -f /tmp/dictate-success

    # Record the focused window's app id *before* the dictation terminal steals
    # focus, so we can pick the right paste shortcut afterwards (terminals paste
    # with Ctrl+Shift+V, other apps with Ctrl+V). app_id covers native Wayland
    # windows; window_properties.class covers XWayland ones. Empty on failure,
    # which falls through to the Ctrl+V default below.
    FOCUSED_APP=$(${pkgs.sway}/bin/swaymsg -t get_tree 2>/dev/null \
      | ${pkgs.jq}/bin/jq -r 'recurse(.nodes[]?, .floating_nodes[]?) | select(.focused == true) | (.app_id // .window_properties.class // "")' \
      | head -n1)

    # Duck currently-playing audio while dictating.
    ${duckStart}

    # Spawn a floating terminal running dictate wrapper
    ${pkgs.foot}/bin/foot \
      --title="Dictation" \
      --window-size-chars=80x15 \
      -e ${dictate-wrapper}/bin/dictate-wrapper 2>/dev/null

    # After foot closes, paste the text if successful
    if [[ -f /tmp/dictate-success ]]; then
      rm -f /tmp/dictate-success
      sleep 0.2
      # The transcription is already on the clipboard (wl-copy in dictate). Paste
      # it with a single keystroke instead of typing it out character by
      # character: the whole content lands in one atomic action, so it can't be
      # split across fields if focus drifts mid-insert.
      #
      # The -s delays space out the modifier sequence so the target app registers
      # the modifiers as held when V arrives; without them wtype fires the events
      # instantly and nothing pastes (the man page recommends -s for exactly these
      # modifier sequences). Terminals paste with Ctrl+Shift+V, everything else
      # (GUI/browser input fields) with Ctrl+V.
      case "''${FOCUSED_APP,,}" in
        kitty | alacritty | foot | xterm | *terminal* )
          ${pkgs.wtype}/bin/wtype -M ctrl -M shift -s 60 -k v -s 60 -m shift -m ctrl 2>/dev/null || true
          ;;
        *)
          ${pkgs.wtype}/bin/wtype -M ctrl -s 60 -k v -s 60 -m ctrl 2>/dev/null || true
          ;;
      esac
    fi
  '';

in
{
  # Module options
  options.services.dictation = {
    enable = mkEnableOption "whisper-based dictation";

    model = mkOption {
      type = types.enum [
        "tiny"
        "base"
        "small"
        "medium"
        "large"
      ];
      default = "base";
      description = "Whisper model to use for transcription";
    };

    modelPath = mkOption {
      type = types.str;
      default = "$HOME/.local/share/whisper/ggml-${cfg.model}.bin";
      description = "Path to the whisper model file";
    };

    whisperPackage = mkOption {
      type = types.package;
      default = pkgs.whisper-cpp;
      description = "The whisper-cpp package to use for transcription";
    };

    pauseMusic = mkEnableOption ''
      pausing media playback (via waybar-mpris) while dictating and resuming it
      afterwards, instead of the default behaviour of lowering the system
      volume to 10%. Requires a running waybar-mpris daemon (as started by the
      waybar module) and an MPRIS source such as mpd via mpdris2'';

    server = {
      enable = mkEnableOption ''
        an always-on whisper-server that keeps the model resident in VRAM.
        Avoids per-invocation model loads (which can fail under VRAM pressure
        from e.g. ollama) and speeds up transcription'';

      host = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "Host/IP the whisper-server listens on.";
      };

      port = mkOption {
        type = types.port;
        default = 8910;
        description = "Port the whisper-server listens on.";
      };
    };
  };

  # Module implementation
  config = mkIf cfg.enable {
    # Install dictation tools
    users.users.${username}.packages = [
      dictate
      dictate-download-model
      dictate-hotkey
      cfg.whisperPackage # Configurable whisper package
      pkgs.sox # For audio recording
      pkgs.wl-clipboard # For Wayland clipboard
      pkgs.pamixer # For volume control
      pkgs.foot # Terminal for dictation hotkey
      pkgs.wtype # For simulating keypresses (Wayland)
    ]
    # waybar-mpris is only needed for the pauseMusic strategy.
    ++ optional cfg.pauseMusic pkgs.waybar-mpris;

    # Always-on whisper-server: loads the model into VRAM once at boot and keeps
    # it resident, so dictation never races ollama for a transient allocation.
    systemd.services.whisper-server = mkIf cfg.server.enable {
      description = "whisper.cpp server (keeps the dictation model resident in VRAM)";
      wantedBy = [ "multi-user.target" ];
      after = [ "local-fs.target" ];
      serviceConfig = {
        User = username;
        SupplementaryGroups = [
          "video"
          "render"
        ];
        ExecStart = "${whisperServerBin} -m ${serverModelFile} --host ${cfg.server.host} --port ${toString cfg.server.port}";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };
}
