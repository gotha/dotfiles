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
      TMPDIR=$(mktemp -d)

      # Cleanup temp directory on exit
      trap "rm -rf $TMPDIR" EXIT

      echo "Starting nightly build at $(date)"

      # Copy repo to temp directory to avoid interfering with local changes
      echo "Copying repo to $TMPDIR..."
      cp -r "$DOTFILES" "$TMPDIR/dotfiles"
      cd "$TMPDIR/dotfiles"

      # Reset to clean state on main branch
      echo "Resetting to main branch..."
      git stash --include-untracked || true
      git checkout main

      # Update flake inputs to latest versions
      echo "Updating flake.lock..."
      nix flake update 2>&1

      # Build devbox config without switching
      # This populates /nix/store with all required packages
      echo "Building devbox configuration..."
      nixos-rebuild build --flake .#devbox 2>&1

      echo "Nightly build completed at $(date)"
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
