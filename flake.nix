{
  description = "my minimal flake";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";

    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy-rs.url = "github:serokell/deploy-rs";

    gotha.url = "github:gotha/nixpkgs?ref=main";

    llm-agents.url = "github:numtide/llm-agents.nix";

    luna-podcatcher = {
      #url = "github:gotha/luna-podcatcher";
      #url = "git+ssh://git@github.com/gotha/luna-podcatcher?ref=refs/tags/v0.1.0";
      url = "git+ssh://git@github.com/gotha/luna-podcatcher?ref=release";
      #url = "git+ssh://git@github.com/gotha/luna-podcatcher?ref=dev";
      #url = "git+file:///home/gotha/Projects/github.com/gotha/luna-podcatcher";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hunk.url = "github:modem-dev/hunk";
  };
  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-stable,
      darwin,
      nix-index-database,
      home-manager,
      nix-vscode-extensions,
      sops-nix,
      gotha,
      deploy-rs,
      llm-agents,
      luna-podcatcher,
      hunk,
      ...
    }:
    let
      configuration =
        { pkgs, ... }:
        {
          nixpkgs.overlays = [
            nix-vscode-extensions.overlays.default
            # Expose gotha/nixpkgs packages under their own namespace
            # (pkgs.gotha.*) so they do not shadow upstream nixpkgs attributes
            # of the same name. The gotha overlay is applied to a fresh
            # nixpkgs (with our allowUnfree) and then narrowed to the curated
            # set declared by `gotha.packages.${system}`.
            (_final: prev: {
              gotha =
                let
                  system = prev.stdenv.hostPlatform.system;
                  overlaid = import nixpkgs {
                    inherit system;
                    config.allowUnfree = true;
                    overlays = [ gotha.overlays.default ];
                  };
                in
                builtins.intersectAttrs gotha.packages.${system} overlaid;
            })
            llm-agents.overlays.shared-nixpkgs
            # Expose the hunk flake's default package as `pkgs.hunk`. The flake
            # does not ship an overlay, so wire it in by system here.
            (_final: prev: {
              hunk = hunk.packages.${prev.stdenv.hostPlatform.system}.default;
            })
            # crush 0.65.3 has tests that create /tmp/crush-test directly.
            # That path is not writable in Darwin's Nix build sandbox, so the
            # checkPhase fails before the Home Manager generation can build.
            (_final: prev: {
              crush = prev.crush.overrideAttrs (
                _old:
                prev.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
                  doCheck = false;
                }
              );
            })
          ];
          _module.args.stablePkgs = import nixpkgs-stable {
            inherit (pkgs.stdenv.hostPlatform) system;
            config.allowUnfree = true;
          };
        };
      distro = rec {
        bae = [
          configuration
          ./distros/bae
          nix-index-database.nixosModules.nix-index
          home-manager.nixosModules.home-manager
        ];
        devbox = [
          configuration
          ./distros/devbox
          nix-index-database.nixosModules.nix-index
          home-manager.nixosModules.home-manager
          sops-nix.nixosModules.sops
          luna-podcatcher.nixosModules.default
        ];
        # devbox minus whatever nixpkgs has no aarch64-linux build for.
        devbox-arm = devbox ++ [ ./distros/devbox-arm ];
        # devbox with Hyprland and quickshell instead of sway and waybar.
        # Layered rather than forked, so devbox stays the source of truth for
        # everything that is not the compositor or the bar.
        h4kbox = devbox ++ [ ./distros/h4kbox ];
        # h4kbox minus whatever cannot work on ARM. Self-contained rather
        # than importing ./distros/devbox-arm: that module rebuilds and
        # mkForces userPackages from devbox's lists, which would discard any
        # list h4kbox grows of its own.
        h4kbox-arm = h4kbox ++ [ ./distros/h4kbox-arm ];
        platypus = [
          configuration
          ./distros/platypus
          nix-index-database.darwinModules.nix-index
          home-manager.darwinModules.home-manager
          sops-nix.darwinModules.sops
          (_: {
            nix.enable = false;
          })
        ];
      };
      wireguard = import ./config/wireguard.nix;
      # Shared by packages.<distro>-qemu (the image) and apps.<distro>-qemu
      # (which boots it) - the app needs config.image.filePath for the filename,
      # which lives on the NixOS config rather than on the derivation.
      #
      # imageId names the image. os/linux/repart-image.nix hardcodes "devbox",
      # which would give every distro the same devbox_1.raw and the same ESP
      # entries, so overlays and boot entries from one would be picked up by
      # another.
      mkQemuImage =
        {
          system,
          modules,
          imageId,
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = modules ++ [
            ./os/linux/virtio.nix
            ./os/linux/repart-image.nix
            ./hosts/qemu1/qemu-no-audio.nix
            {
              system.image.id = nixpkgs.lib.mkForce imageId;
              image.repart.name = nixpkgs.lib.mkForce imageId;
            }
          ];
          specialArgs = { inherit sops-nix; };
        };
      # systemd-repart writes the .raw into the build directory and only moves
      # it to $out afterwards, and Minimize = "guess" makes it first stage a
      # full copy of the closure under $TMPDIR just to measure the smallest
      # partition that fits. So a ~25 GiB closure needs ~25 GiB of scratch on
      # top of the image itself, all of it in the build directory.
      #
      # On a Mac these are built by Determinate Nix's external Linux builder,
      # which gives a build a 3.9 GiB tmpfs - half the builder VM's 8 GiB of
      # RAM - for exactly that. The stock phases die on
      #   Failed to copy '/nix/store/...' to '/build/.#repart...': No space
      #   left on device
      # and the message is swallowed by the `| tee` in the upstream buildPhase,
      # so the build just fails with three blank lines.
      #
      # $out lives on the real store, with hundreds of GB free, so put both the
      # scratch tree and the image there. No-op on a Linux builder, where the
      # build directory is disk-backed anyway.
      #
      # This replaces buildPhase/installPhase from nixpkgs'
      # nixos/modules/image/repart-image.nix, so it also drops that
      # installPhase's compression step - nothing here sets
      # image.repart.compression.enable.
      repartImageOnOut =
        nixos:
        nixos.config.system.build.image.overrideAttrs (_old: {
          buildPhase = ''
            runHook preBuild

            scratch="$out/.repart-scratch"
            mkdir -p "$scratch"
            export TMPDIR="$scratch"

            echo "Building image with systemd-repart..."
            unshare --map-root-user fakeroot systemd-repart \
              "''${systemdRepartFlags[@]}" \
              "$out/${nixos.config.image.filePath}" \
              | tee repart-output.json

            rm -rf "$scratch"

            runHook postBuild
          '';
          # The image is already in $out; only the json report still has to move.
          installPhase = ''
            runHook preInstall
            mv -v repart-output.json "$out"
            runHook postInstall
          '';
        });
      devboxQemuImage = mkQemuImage {
        system = "x86_64-linux";
        modules = distro.devbox;
        imageId = "devbox";
      };
      devboxQemuImageArm = mkQemuImage {
        system = "aarch64-linux";
        modules = distro.devbox-arm;
        imageId = "devbox";
      };
      h4kboxQemuImage = mkQemuImage {
        system = "x86_64-linux";
        modules = distro.h4kbox;
        imageId = "h4kbox";
      };
      h4kboxQemuImageArm = mkQemuImage {
        system = "aarch64-linux";
        modules = distro.h4kbox-arm;
        imageId = "h4kbox";
      };
      # The qemu invocation depends on the host architecture, not on which
      # distro is inside the image, so devbox and h4kbox share these. Note the
      # DEVBOX_QEMU_* environment variables are read by every runner, h4kbox
      # included - they are documented under that name in the README, so they
      # keep it rather than growing a per-distro prefix.
      x86QemuCommand = pkgs: ''
        exec ${pkgs.qemu_kvm}/bin/qemu-system-x86_64 \
          -machine q35 -enable-kvm -cpu host -smp 4 -m 8G \
          -drive if=pflash,format=raw,unit=0,readonly=on,file=${pkgs.OVMF.fd}/FV/OVMF_CODE.fd \
          -drive if=pflash,format=raw,unit=1,file="$vars" \
          -drive file="$disk",format=qcow2,if=virtio \
          -netdev user,id=net0,hostfwd=tcp::2222-:22 \
          -device virtio-net-pci,netdev=net0 \
          -device virtio-vga -display "''${DEVBOX_QEMU_DISPLAY:-gtk}" \
          ''${QEMU_OPTS:-}
      '';
      armQemuCommand = { pkgs, firmware }: ''
        # virt has no VGA, so virtio-gpu-pci rather than virtio-vga. There
        # is no GPU passthrough either way - the compositor lands on
        # llvmpipe, sway and Hyprland alike.
        #
        # No xres/yres here on purpose. They set the initial mode, but
        # pinning them cost the dynamic resize: cocoa's windowDidResize
        # feeds dpy_set_ui_info into virtio_gpu_ui_info, which rewrites
        # req_state and regenerates the EDID, so the guest follows the
        # window and fills the screen when you go fullscreen. Setting
        # them left the guest fixed at 1080p, centred in a black frame.
        #
        # full-grab installs a global event tap so system combos reach
        # the guest instead of the host - without it alt-1 goes to
        # aerospace (see home-manager/aerospace/aerospace.toml) and the
        # guest compositor never sees it. macOS only honours the tap once
        # qemu has Accessibility permission, and that is granted per binary
        # path, so it has to be re-granted whenever the qemu store path
        # changes. DEVBOX_QEMU_DISPLAY overrides the whole string, so
        # DEVBOX_QEMU_DISPLAY=cocoa turns the grab back off.
        #
        # virt also has no PS/2 controller - x86 q35 gets a keyboard and
        # mouse for free from i8042, virt gets nothing - so without the
        # three -device lines below the guest has no input devices at all
        # and the greeter never sees a keystroke, however much the host
        # window grabs the cursor. USB HID rather than virtio-input
        # because the guest kernel has usbcore, usbhid, hid-generic and
        # xhci-pci built in, while virtio_input is only a loadable
        # module. usb-tablet reports absolute coordinates, so the pointer
        # follows the host cursor instead of needing a grab.
        exec ${pkgs.qemu}/bin/qemu-system-aarch64 \
          -machine virt,accel=hvf -cpu host -smp 4 -m 8G \
          -drive if=pflash,format=raw,unit=0,readonly=on,file=${firmware}/edk2-aarch64-code.fd \
          -drive if=pflash,format=raw,unit=1,file="$vars" \
          -drive file="$disk",format=qcow2,if=virtio \
          -netdev user,id=net0,hostfwd=tcp::2222-:22 \
          -device virtio-net-pci,netdev=net0 \
          -device virtio-gpu-pci \
          -display "''${DEVBOX_QEMU_DISPLAY:-cocoa,full-grab=on}" \
          -device qemu-xhci,id=usb \
          -device usb-kbd,bus=usb.0 \
          -device usb-tablet,bus=usb.0 \
          ''${QEMU_OPTS:-}
      '';
      # The two runners differ only in the qemu binary, the UEFI firmware and
      # the machine/accelerator flags. Everything around the writable overlay
      # is identical, so build both from one template and keep that logic in
      # one place.
      mkQemuApp =
        {
          # Names the runner script and appears in the app description, so the
          # h4kbox runner is not another store path called devbox-qemu.
          name,
          pkgs,
          qemu,
          imageFile,
          defaultDisk,
          varsTemplate,
          qemuCommand,
        }:
        let
          # Identifies the exact command line below, qemu's store path and all,
          # so a qemu bump counts as a change too. Only used to decide whether
          # the varstore is still valid.
          qemuCommandHash = builtins.hashString "sha256" qemuCommand;
        in
        {
          type = "app";
          meta.description = "Boot the self-contained ${name} image in a QEMU VM";
          program = toString (
            pkgs.writeShellScript "${name}-qemu" ''
              set -euo pipefail

              disk="''${DEVBOX_QEMU_DISK:-${defaultDisk}}"
              vars="''${disk%.qcow2}-efivars.fd"
              # A prebuilt .raw can be booted straight from disk. The store path
              # below is the default, but a Mac cannot build a Linux image at
              # all, so pointing at a file copied in from a Linux builder is the
              # only way to run one here.
              image="''${DEVBOX_QEMU_IMAGE:-${imageFile}}"
              # qcow2 resolves a relative backing path against the qcow2's own
              # directory, not the working directory, so make it absolute here
              # or the overlay ends up pointing at qemu/qemu/devbox_1.raw.
              case "$image" in
                /*) ;;
                *) image="$PWD/$image" ;;
              esac
              if [ "''${1-}" = "--fresh" ]; then
                rm -f "$disk" "$vars"
              fi

              # The overlay is only valid for the exact image it was created
              # from, so a disk left behind by an older build has to go. Left
              # in place it either boots the previous image, breaks once that
              # store path is garbage collected, or - if it predates this
              # setup and has no ESP at all - dies in the firmware with
              # "BdsDxe: failed to load Boot0002 ... Not Found".
              if [ -e "$disk" ]; then
                backing=$(${qemu}/bin/qemu-img info --output=json "$disk" \
                  | ${pkgs.jq}/bin/jq -r '."backing-filename" // ""')
                if [ "$backing" != "$image" ]; then
                  echo "devbox-qemu: $disk was built from a different image, recreating it" >&2
                  echo "devbox-qemu:   had: ''${backing:-(none)}" >&2
                  echo "devbox-qemu:   now: $image" >&2
                  rm -f "$disk" "$vars"
                fi
              fi

              # Back a writable qcow2 onto the image rather than copying 47G.
              if [ ! -e "$disk" ]; then
                mkdir -p "$(dirname "$disk")"
                ${qemu}/bin/qemu-img create -f qcow2 \
                  -b "$image" -F raw "$disk" >/dev/null
              fi
              # The EFI variable store remembers Boot#### entries by device
              # path, so changing the qemu command line - adding a PCI device
              # shifts the enumeration - leaves entries that no longer resolve.
              # The firmware then falls through to the internal shell:
              #   BdsDxe: loading Boot0002 "EFI Internal Shell"
              # which reads as "the OS will not boot any more" even though the
              # image is fine. Discard the varstore whenever the command line
              # it was written against has changed. The disk, and so the guest's
              # state, is deliberately left alone: the ESP carries a fallback
              # \EFI\BOOT\BOOT*.EFI, so a blank varstore boots on its own.
              stamp="''${disk%.qcow2}-cmdline.stamp"
              if [ ! -e "$stamp" ] || [ "$(cat "$stamp")" != "${qemuCommandHash}" ]; then
                if [ -e "$vars" ]; then
                  echo "devbox-qemu: qemu command line changed, resetting EFI variables" >&2
                  rm -f "$vars"
                fi
              fi

              # The firmware needs its own writable copy of the variable store.
              # Spelled out rather than `install -D`, which is a GNU extension
              # the install(1) in macOS base does not have.
              if [ ! -e "$vars" ]; then
                mkdir -p "$(dirname "$vars")"
                cp ${varsTemplate} "$vars"
                chmod 600 "$vars"
              fi

              mkdir -p "$(dirname "$stamp")"
              printf '%s' "${qemuCommandHash}" > "$stamp"

              # UEFI, not BIOS: the image boots a UKI from its ESP.
              # DEVBOX_QEMU_DISPLAY=none plus QEMU_OPTS='-serial stdio' runs it
              # headless, which is the only way to see the boot at all.
              ${qemuCommand}
            ''
          );
        };
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      linterChecks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          deadnix = pkgs.runCommand "deadnix-check" { nativeBuildInputs = [ pkgs.deadnix ]; } ''
            cd ${self}
            deadnix --fail .
            touch $out
          '';

          statix = pkgs.runCommand "statix-check" { nativeBuildInputs = [ pkgs.statix ]; } ''
            cd ${self}
            statix check .
            touch $out
          '';

          nixfmt =
            pkgs.runCommand "nixfmt-check"
              {
                nativeBuildInputs = [
                  pkgs.fd
                  pkgs.nixfmt
                ];
              }
              ''
                cd ${self}
                fd -e nix -X nixfmt --check {}
                touch $out
              '';
        }
      );
      deployChecks = builtins.mapAttrs (
        _system: deployLib: deployLib.deployChecks self.deploy
      ) deploy-rs.lib;
    in
    {

      darwinConfigurations = {
        "HS-DDH669533W" = darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = distro.platypus ++ [ ./hosts/mucie ];
          specialArgs = {
            inherit sops-nix;
            stablePkgs = import nixpkgs-stable {
              system = "aarch64-darwin";
              config.allowUnfree = true;
            };
          };
        };
      };

      nixosConfigurations = {
        bae = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = distro.bae ++ [ ./hosts/qemu1 ];
          specialArgs = {
            inherit sops-nix;
            stablePkgs = import nixpkgs-stable {
              system = "x86_64-linux";
              config.allowUnfree = true;
            };
          };
        };
        bastion = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = distro.bae ++ [ ./hosts/bastion ];
          specialArgs = {
            inherit sops-nix;
            stablePkgs = import nixpkgs-stable {
              system = "x86_64-linux";
              config.allowUnfree = true;
            };
          };
        };
        devbox = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = distro.devbox ++ [
            ./hosts/qemu1
            ./os/linux/virtio.nix
          ];
          specialArgs = {
            inherit sops-nix;
            stablePkgs = import nixpkgs-stable {
              system = "x86_64-linux";
              config.allowUnfree = true;
            };
          };
        };

        # Same shape as devbox above, so h4kbox can be built and switched to on
        # a real machine rather than only booted as an image.
        h4kbox = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = distro.h4kbox ++ [
            ./hosts/qemu1
            ./os/linux/virtio.nix
          ];
          specialArgs = {
            inherit sops-nix;
            stablePkgs = import nixpkgs-stable {
              system = "x86_64-linux";
              config.allowUnfree = true;
            };
          };
        };

        # The aarch64 h4kbox is only ever run as the qemu image, so this is
        # that image's nixosSystem rather than a second one built the way
        # h4kbox above is. Anything else would disagree with the running
        # image about the root device and the bootloader: hosts/qemu1 mounts
        # / by label and installs grub, while os/linux/repart-image.nix
        # mkForces / to /dev/disk/by-partlabel/root and turns grub off.
        #
        # Note the ESP is written once, when the image is built, so a switch
        # here takes effect immediately but does not survive a reboot - the
        # baked UKI still has init= pinned to the generation the image
        # shipped with. Rebuild the image to make a change persist.
        h4kbox-arm = h4kboxQemuImageArm;

        lucie = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = distro.devbox ++ [ ./hosts/lucie ];
          specialArgs = {
            inherit sops-nix;
            stablePkgs = import nixpkgs-stable {
              system = "x86_64-linux";
              config.allowUnfree = true;
            };
          };
        };
      };

      packages = {
        x86_64-linux = {
          bae-qemu =
            let
              config = nixpkgs.lib.nixosSystem {
                system = "x86_64-linux";
                modules = distro.bae ++ [
                  ./hosts/qemu1
                  ./os/linux/virtio.nix
                ];
                specialArgs = { inherit sops-nix; };
              };
            in
            config.config.system.build.images.qemu;
          devbox-qemu = repartImageOnOut devboxQemuImage;
          h4kbox-qemu = repartImageOnOut h4kboxQemuImage;
        };
        aarch64-linux = {
          devbox-qemu = repartImageOnOut devboxQemuImageArm;
          h4kbox-qemu = repartImageOnOut h4kboxQemuImageArm;
        };
      };

      formatter = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        pkgs.writeShellScriptBin "fmt" ''
          exec ${pkgs.fd}/bin/fd -e nix -X ${pkgs.nixfmt}/bin/nixfmt {}
        ''
      );

      apps = {
        x86_64-linux = {
          devbox-qemu =
            let
              pkgs = nixpkgs.legacyPackages.x86_64-linux;
            in
            mkQemuApp {
              inherit pkgs;
              qemu = pkgs.qemu_kvm;
              imageFile = "${self.packages.x86_64-linux.devbox-qemu}/${devboxQemuImage.config.image.filePath}";
              name = "devbox";
              defaultDisk = "qemu/devbox.qcow2";
              varsTemplate = "${pkgs.OVMF.fd}/FV/OVMF_VARS.fd";
              qemuCommand = x86QemuCommand pkgs;
            };

          h4kbox-qemu =
            let
              pkgs = nixpkgs.legacyPackages.x86_64-linux;
            in
            mkQemuApp {
              inherit pkgs;
              qemu = pkgs.qemu_kvm;
              imageFile = "${self.packages.x86_64-linux.h4kbox-qemu}/${h4kboxQemuImage.config.image.filePath}";
              name = "h4kbox";
              defaultDisk = "qemu/h4kbox.qcow2";
              varsTemplate = "${pkgs.OVMF.fd}/FV/OVMF_VARS.fd";
              qemuCommand = x86QemuCommand pkgs;
            };
        };

        aarch64-darwin = {
          # devbox-arm on Apple silicon. accel=hvf with -cpu host is real
          # hardware virtualisation, so the guest runs at native speed - the
          # whole point of building an ARM image rather than emulating the
          # x86 one.
          devbox-qemu =
            let
              pkgs = nixpkgs.legacyPackages.aarch64-darwin;
              # qemu ships the ARM edk2 build itself, both blobs already padded
              # to the 64M that the virt machine's pflash wants, so there is no
              # separate OVMF package to chase on darwin.
              firmware = "${pkgs.qemu}/share/qemu";
            in
            mkQemuApp {
              inherit pkgs;
              inherit (pkgs) qemu;
              imageFile = "${self.packages.aarch64-linux.devbox-qemu}/${devboxQemuImageArm.config.image.filePath}";
              name = "devbox";
              defaultDisk = "qemu/devbox-arm.qcow2";
              varsTemplate = "${firmware}/edk2-arm-vars.fd";
              qemuCommand = armQemuCommand { inherit pkgs firmware; };
            };

          # h4kbox-arm on Apple silicon - the fast path for testing Hyprland and
          # quickshell, same hvf virtualisation as devbox-qemu. Separate overlay
          # and image name, so the two can be run and kept side by side.
          h4kbox-qemu =
            let
              pkgs = nixpkgs.legacyPackages.aarch64-darwin;
              firmware = "${pkgs.qemu}/share/qemu";
            in
            mkQemuApp {
              inherit pkgs;
              inherit (pkgs) qemu;
              imageFile = "${self.packages.aarch64-linux.h4kbox-qemu}/${h4kboxQemuImageArm.config.image.filePath}";
              name = "h4kbox";
              defaultDisk = "qemu/h4kbox-arm.qcow2";
              varsTemplate = "${firmware}/edk2-arm-vars.fd";
              qemuCommand = armQemuCommand { inherit pkgs firmware; };
            };

          # The x86_64 image on Apple silicon. No hardware acceleration exists for
          # a cross-architecture guest, so this is full TCG emulation and is slow -
          # fine over ssh, rough for sway. It is a stopgap; devbox-qemu (the ARM
          # image) is the fast path. Nix will not build the x86_64 image on a Mac
          # either, so the image has to be copied in from a Linux builder first.
          devbox-qemu-x86 =
            let
              pkgs = nixpkgs.legacyPackages.aarch64-darwin;
              firmware = "${pkgs.qemu}/share/qemu";
            in
            mkQemuApp {
              inherit pkgs;
              inherit (pkgs) qemu;
              # A plain path, not the store path: interpolating the latter would
              # make the image a build input of this script, and a Mac cannot
              # build a Linux image - `nix run` would try, and fail, before it
              # ever got to booting anything. Relative to the working directory,
              # like defaultDisk. Override with DEVBOX_QEMU_IMAGE.
              imageFile = "qemu/devbox_1.raw";
              name = "devbox";
              defaultDisk = "qemu/devbox-x86.qcow2";
              varsTemplate = "${firmware}/edk2-i386-vars.fd";
              qemuCommand = ''
                # -cpu max, not host: host means "expose the physical cpu", which
                # needs hardware acceleration, and there is none here.
                exec ${pkgs.qemu}/bin/qemu-system-x86_64 \
                  -machine q35 -accel tcg -cpu max -smp 4 -m 8G \
                  -drive if=pflash,format=raw,unit=0,readonly=on,file=${firmware}/edk2-x86_64-code.fd \
                  -drive if=pflash,format=raw,unit=1,file="$vars" \
                  -drive file="$disk",format=qcow2,if=virtio \
                  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
                  -device virtio-net-pci,netdev=net0 \
                  -device virtio-vga -display "''${DEVBOX_QEMU_DISPLAY:-cocoa}" \
                  ''${QEMU_OPTS:-}
              '';
            };
        };
      };

      devShells = {
        x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.mkShell {
          packages = with nixpkgs.legacyPackages.x86_64-linux; [
            nixd
            qrencode
          ];
        };

        aarch64-darwin.default = nixpkgs.legacyPackages.aarch64-darwin.mkShell {
          packages = with nixpkgs.legacyPackages.aarch64-darwin; [
            nixd
            qrencode
          ];
        };

        # For working on this repo from inside the aarch64 h4kbox/devbox VM,
        # where .envrc's `use flake` would otherwise fail outright.
        aarch64-linux.default = nixpkgs.legacyPackages.aarch64-linux.mkShell {
          packages = with nixpkgs.legacyPackages.aarch64-linux; [
            nixd
            qrencode
          ];
        };
      };

      deploy.nodes = {
        bastion = {
          hostname = wireguard.bastion.publicIP;
          remoteBuild = false;
          sshUser = wireguard.bastion.username;
          profiles.system = {
            user = "root";
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.bastion;
          };
        };
      };

      # This is highly advised, and will prevent many possible mistakes
      checks = nixpkgs.lib.recursiveUpdate deployChecks linterChecks;
    };
}
