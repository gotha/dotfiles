# Nightly build service to pre-build devbox configuration
# Builds packages overnight so they're ready when you upgrade
{ pkgs, username, ... }:
{
  # When disk space runs low, have the daemon collect garbage mid-build; once
  # free space drops below min-free it deletes until max-free is available,
  # rather than failing the build or wedging the filesystem.
  #
  # Sized for this host's 3.6 TB of storage and the CUDA closure the nightly
  # build pulls in. These belong here rather than in os/nixos/gc.nix, which
  # distros/bae shares with bastion: a 25 GB droplet never has 20 GiB free, so
  # there the same numbers make every nix operation trigger a collection that
  # cannot reach its target - which then deletes paths a deploy is still
  # copying in, before they are rooted.
  nix.settings = {
    min-free = 20 * 1024 * 1024 * 1024; # 20 GiB
    max-free = 100 * 1024 * 1024 * 1024; # 100 GiB
  };

  systemd.services.nix-nightly-build = {
    description = "Nightly NixOS devbox configuration build";
    serviceConfig = {
      Type = "oneshot";
      User = "root";

      CPUWeight = 20;

      MemoryHigh = "8G";
      MemoryMax = "12G";

      IOReadBandwidthMax = "/ 300M";
      IOWriteBandwidthMax = "/ 150M";

      IOWeight = 10;

      TimeoutStartSec = "4h";
      TimeoutStopSec = "30s";
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

      # Refuse to start without room for a large closure. This is a speculative
      # prebuild; filling the last of the root filesystem for it is never worth
      # it, and ext4 allocation degrades badly near full. Failing loudly beats
      # skipping quietly - "systemctl --failed" is then the disk-space alarm.
      AVAIL_GB=$(($(df --output=avail --block-size=1G /nix/store | tail -n1)))
      if [ "$AVAIL_GB" -lt 150 ]; then
        echo "Only ''${AVAIL_GB}G free on /nix/store, need 150G. Refusing to build." >&2
        exit 1
      fi

      # Clean up old builds. Each one leaves a ./result symlink that nix
      # registers as an indirect GC root, so every retained day pins an entire
      # system closure - CUDA, ollama and all. Seven days of those was a
      # meaningful share of the 96% full root filesystem.
      find /var/lib/nix-nightly -maxdepth 1 -name "dotfiles-*" -type d -mtime +3 -exec rm -rf {} \; 2>/dev/null || true

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
      # --max-jobs/--cores bound how much of the machine a cache miss can claim;
      # without them a CUDA rebuild fans out across every core at once.
      echo "Building lucie configuration..."
      nixos-rebuild build --flake .#lucie --max-jobs 2 --cores 4 2>&1

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
