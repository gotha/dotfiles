# Nightly build, the darwin counterpart of hosts/lucie/nightly-build.nix.
#
# Updates flake.lock, builds this host's configuration without switching, and
# expires old builds. The point is that a morning `darwin-rebuild switch` finds
# the closure already in the store rather than compiling it while you wait.
#
# launchd rather than systemd, and so no CPUWeight/MemoryMax/IOWeight: launchd
# has no cgroup equivalent. Nice and LowPriorityIO are the whole toolbox, with
# the real bound coming from nix's own --max-jobs and --cores below.
{ pkgs, username, ... }:
let
  workDir = "/var/lib/nix-nightly";

  # Builds are kept this long, and their `result` symlinks are what stops nix
  # collecting the closures they point at. Each one pins a whole system, so
  # this is a disk-space decision rather than a preference - lucie keeps 3 for
  # exactly that reason.
  keepDays = 3;

  # A speculative prebuild should never be the thing that fills the disk.
  minFreeGB = 60;
in
{
  launchd.daemons.nix-nightly-build = {
    script = ''
      set -euo pipefail

      DOTFILES="/Users/${username}/Projects/github.com/gotha/dotfiles"
      DATE=$(date +%Y-%m-%d)
      BUILD_DIR="${workDir}/dotfiles-$DATE"

      echo "Starting nightly build at $(date)"

      # df -Pk rather than -g or --output: this host has GNU coreutils on PATH
      # in some shells and BSD df in others, and -P -k is the spelling both
      # implementations accept.
      AVAIL_GB=$(df -Pk /nix/store | tail -1 | awk '{print int($4/1048576)}')
      if [ "$AVAIL_GB" -lt ${toString minFreeGB} ]; then
        echo "Only ''${AVAIL_GB}G free on /nix/store, need ${toString minFreeGB}G. Refusing to build." >&2
        exit 1
      fi

      # Expire old builds first, so their closures are collectable before this
      # one adds another. Deleting the directory drops the result symlink with
      # it, which is what actually releases the gc root.
      find ${workDir} -maxdepth 1 -name "dotfiles-*" -type d -mtime +${toString keepDays} \
        -exec rm -rf {} \; 2>/dev/null || true

      # Build from a copy. The service runs as root, and running git and nix
      # over the real checkout would leave root-owned files in it.
      mkdir -p ${workDir}
      rm -rf "$BUILD_DIR"
      cp -R "$DOTFILES" "$BUILD_DIR"
      cd "$BUILD_DIR"

      echo "Resetting to main branch..."
      git stash --include-untracked || true
      git checkout main

      echo "Updating flake.lock..."
      nix flake update 2>&1

      # Built, not switched: this only warms the store. --max-jobs and --cores
      # keep a cache miss from taking the whole machine, which matters more
      # here than on a server - it is a laptop that may be in use.
      echo "Building darwin configuration..."
      darwin-rebuild build --flake . --max-jobs 2 --cores 4 2>&1

      ln -sfn "$BUILD_DIR" ${workDir}/latest

      echo "Nightly build completed at $(date)"
      echo "flake.lock available at: $BUILD_DIR/flake.lock"
    '';

    # nix.enable is false for this distro, so nix-darwin does not manage
    # /etc/nix/nix.conf and there is no nix.gc to lean on. Collecting here
    # keeps the policy in one place with the thing that creates the garbage.
    serviceConfig = {
      RunAtLoad = false;
      StartCalendarInterval = [
        {
          Hour = 3;
          Minute = 0;
        }
      ];
      # Background gets the lowest CPU and I/O priority macOS offers, and is
      # what keeps an overnight build from being felt if the lid is open.
      ProcessType = "Background";
      LowPriorityIO = true;
      Nice = 10;
      StandardOutPath = "/var/log/nix-nightly-build.log";
      StandardErrorPath = "/var/log/nix-nightly-build.log";
      EnvironmentVariables = {
        PATH = "/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin:/usr/sbin:/sbin";
        # nix needs a home for its caches; without this it uses / and warns.
        HOME = "/var/root";
      };
    };
  };

  environment.systemPackages = [ pkgs.git ];
}
