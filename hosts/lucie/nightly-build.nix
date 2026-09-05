# Nightly build service to pre-build devbox configuration
# Builds packages overnight so they're ready when you upgrade
{ pkgs, username, ... }:
{
  systemd.services.nix-nightly-build = {
    description = "Nightly NixOS devbox configuration build";
    serviceConfig = {
      Type = "oneshot";
      User = "root";

      # Resource containment. On 2026-08-28 a nixpkgs bump pulled in a fresh
      # CUDA 12.9 closure; the build wrote 47 GB, pinned 8 GB of RSS and
      # starved the host of I/O for 4.5 hours until it needed a hardware reset.
      # The guards in place at the time (Nice + IOSchedulingClass) did nothing:
      #
      #   - ionice scheduling classes are only honoured by BFQ, and
      #     /sys/block/nvme0n1/queue/scheduler here reads "[none] mq-deadline
      #     kyber". IOSchedulingClass was dead config, so it is gone.
      #   - nice arbitrates between threads inside one cgroup, but systemd puts
      #     every unit in its own, where cpu.weight is what matters.
      #
      # What follows are cgroup v2 knobs, which do apply on this host.

      # CPU: default weight is 100, so the build gets a fifth of a contended
      # core's worth of share against anything else that wants to run.
      CPUWeight = 20;

      # Memory: MemoryHigh throttles and forces reclaim (including writeback of
      # this cgroup's own dirty page cache) rather than letting pressure spill
      # onto the host; MemoryMax is the hard stop. A build that genuinely needs
      # more than 12 G dies in its own cgroup instead of inviting the global OOM
      # killer to pick a victim - last time it chose chromium.
      MemoryHigh = "8G";
      MemoryMax = "12G";

      # I/O: blk-throttle runs above the elevator, so unlike ionice these caps
      # hold under the "none" scheduler. Sized so a worst-case closure still
      # lands in well under an hour while leaving the NVMe mostly free for
      # Nextcloud, Plex and journald.
      IOReadBandwidthMax = "/ 300M";
      IOWriteBandwidthMax = "/ 150M";
      # Only honoured with BFQ or blk-iocost, but harmless and correct if either
      # is ever enabled here.
      IOWeight = 10;

      # A normal run takes 1-5 minutes; the worst healthy run on record was
      # ~40. Four hours was enough budget to wedge the box overnight.
      TimeoutStartSec = "1h";
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
