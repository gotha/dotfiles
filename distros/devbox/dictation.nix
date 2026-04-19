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

        # Restore volume if needed
        if [[ -f /tmp/dictate-original-volume ]]; then
          ORIGINAL_VOL=$(cat /tmp/dictate-original-volume)
          ${pkgs.pamixer}/bin/pamixer --set-volume "$ORIGINAL_VOL"
          rm -f /tmp/dictate-original-volume
        fi

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

    # Restore original volume if it was lowered (for dictate-hotkey)
    if [[ -f /tmp/dictate-original-volume ]]; then
      ORIGINAL_VOL=$(cat /tmp/dictate-original-volume)
      ${pkgs.pamixer}/bin/pamixer --set-volume "$ORIGINAL_VOL"
      rm -f /tmp/dictate-original-volume
    fi

    echo "Transcribing..."

    # Transcribe with whisper.cpp
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

    RESULT=$(cat "$WHISPER_OUTPUT" | grep -v "^\[" | tr -d '\n' | sed 's/^[[:space:]]*//')
    rm -f "$WHISPER_OUTPUT" "$WHISPER_ERROR"

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
  # Mutes audio, opens a floating terminal for dictation, unmutes after
  dictate-hotkey = pkgs.writeShellScriptBin "dictate-hotkey" ''
    # Clean up any previous success marker
    rm -f /tmp/dictate-success

    # Save current volume and lower to 10% during dictation
    ${pkgs.pamixer}/bin/pamixer --get-volume > /tmp/dictate-original-volume
    ${pkgs.pamixer}/bin/pamixer --set-volume 10

    # Spawn a floating terminal running dictate wrapper
    ${pkgs.foot}/bin/foot \
      --title="Dictation" \
      --window-size-chars=80x15 \
      -e ${dictate-wrapper}/bin/dictate-wrapper 2>/dev/null

    # After foot closes, type the text if successful
    if [[ -f /tmp/dictate-success ]]; then
      rm -f /tmp/dictate-success
      sleep 0.2
      # Get text from clipboard and type it directly (avoids Ctrl+V issues)
      ${pkgs.wl-clipboard}/bin/wl-paste --no-newline --type text/plain 2>/dev/null | ${pkgs.wtype}/bin/wtype -d 5 - 2>/dev/null || true
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
    ];
  };
}
