# Nightly build service to pre-build devbox configuration
# Builds packages overnight so they're ready when you upgrade
{ pkgs, username, ... }:
{
  systemd.services.nix-nightly-build = {
    description = "Nightly NixOS devbox configuration build";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      # Low priority to avoid impacting system usage
      Nice = 19;
      IOSchedulingClass = "idle";
      # Timeout after 4 hours
      TimeoutStartSec = "4h";
    };
    path = with pkgs; [
      git
      nix
      nixos-rebuild
    ];
    script = ''
      set -euo pipefail

      DOTFILES="/home/${username}/Projects/github.com/gotha/dotfiles"
      DATE=$(date +%Y-%m-%d)
      BUILD_DIR="/var/lib/nix-nightly/dotfiles-$DATE"

      echo "Starting nightly build at $(date)"

      # Clean up old builds (keep last 7 days)
      find /var/lib/nix-nightly -maxdepth 1 -name "dotfiles-*" -type d -mtime +7 -exec rm -rf {} \; 2>/dev/null || true

      # Create build directory
      mkdir -p /var/lib/nix-nightly
      rm -rf "$BUILD_DIR"
      cp -r "$DOTFILES" "$BUILD_DIR"
      cd "$BUILD_DIR"

      # Reset to clean state
      echo "Resetting to main branch..."
      git stash --include-untracked || true
      git checkout main

      # Update flake inputs to latest versions
      echo "Updating flake.lock..."
      nix flake update 2>&1

      # Build lucie config without switching
      # This populates /nix/store with all required packages
      echo "Building lucie configuration..."
      nixos-rebuild build --flake .#lucie 2>&1

      # Create symlink to latest build
      ln -sfn "$BUILD_DIR" /var/lib/nix-nightly/latest

      echo "Nightly build completed at $(date)"
      echo "flake.lock available at: $BUILD_DIR/flake.lock"
    '';
  };

  systemd.timers.nix-nightly-build = {
    description = "Nightly NixOS devbox configuration build timer";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 03:00:00";
      Persistent = true;
      RandomizedDelaySec = "30min";
    };
  };
}
