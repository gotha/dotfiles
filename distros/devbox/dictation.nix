# Speech-to-text dictation using whisper.cpp
# Usage: dictate (records audio, transcribes with whisper, types result)
{ config, pkgs, lib, username, ... }:

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

    echo "Recording... Press Enter to stop"

    # Record audio using sox with a time limit trick for graceful stop
    # We'll record to a temp file and use SIGINT for proper buffer flushing
    ${pkgs.sox}/bin/rec -q -r 16000 -c 1 "$TEMP_WAV" &
    RECORD_PID=$!

    # Wait for Enter key
    read -r

    # Keep recording for 1.5 more seconds to capture end of sentence
    echo "Finishing..."
    sleep 1.5

    # Use SIGINT (like Ctrl+C) for graceful shutdown with buffer flush
    kill -INT $RECORD_PID 2>/dev/null || true
    wait $RECORD_PID 2>/dev/null || true

    # Ensure file is fully written
    sync
    sleep 0.3

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

      # Copy to clipboard (Wayland or X11)
      if [[ "$XDG_SESSION_TYPE" == "wayland" ]]; then
        echo -n "$RESULT" | ${pkgs.wl-clipboard}/bin/wl-copy
      else
        echo -n "$RESULT" | ${pkgs.xclip}/bin/xclip -selection clipboard
      fi
      echo "(copied to clipboard)"
    else
      echo "No speech detected"
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

in
{
  # Module options
  options.services.dictation = {
    enable = mkEnableOption "whisper-based dictation";

    model = mkOption {
      type = types.enum [ "tiny" "base" "small" "medium" "large" ];
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
      cfg.whisperPackage  # Configurable whisper package
      pkgs.sox            # For audio recording
      pkgs.wl-clipboard   # For Wayland clipboard
      pkgs.xclip          # For X11 clipboard
    ];
  };
}
