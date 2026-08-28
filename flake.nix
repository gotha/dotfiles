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
      # Shared by packages.devbox-qemu (the image) and apps.devbox-qemu (which
      # boots it) - the app needs config.image.filePath for the filename, which
      # lives on the NixOS config rather than on the derivation.
      mkDevboxQemuImage =
        { system, modules }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          modules = modules ++ [
            ./os/linux/virtio.nix
            ./os/linux/repart-image.nix
          ];
          specialArgs = { inherit sops-nix; };
        };
      devboxQemuImage = mkDevboxQemuImage {
        system = "x86_64-linux";
        modules = distro.devbox;
      };
      devboxQemuImageArm = mkDevboxQemuImage {
        system = "aarch64-linux";
        modules = distro.devbox-arm;
      };
      # The two runners differ only in the qemu binary, the UEFI firmware and
      # the machine/accelerator flags. Everything around the writable overlay
      # is identical, so build both from one template and keep that logic in
      # one place.
      mkDevboxQemuApp =
        {
          pkgs,
          qemu,
          imageFile,
          defaultDisk,
          varsTemplate,
          qemuCommand,
        }:
        {
          type = "app";
          meta.description = "Boot the self-contained devbox image in a QEMU VM";
          program = toString (
            pkgs.writeShellScript "devbox-qemu" ''
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
              # The firmware needs its own writable copy of the variable store.
              # Spelled out rather than `install -D`, which is a GNU extension
              # the install(1) in macOS base does not have.
              if [ ! -e "$vars" ]; then
                mkdir -p "$(dirname "$vars")"
                cp ${varsTemplate} "$vars"
                chmod 600 "$vars"
              fi

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
          devbox-qemu = devboxQemuImage.config.system.build.image;
        };
        aarch64-linux = {
          devbox-qemu = devboxQemuImageArm.config.system.build.image;
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
        x86_64-linux.devbox-qemu =
          let
            pkgs = nixpkgs.legacyPackages.x86_64-linux;
          in
          mkDevboxQemuApp {
            inherit pkgs;
            qemu = pkgs.qemu_kvm;
            imageFile = "${self.packages.x86_64-linux.devbox-qemu}/${devboxQemuImage.config.image.filePath}";
            defaultDisk = "qemu/devbox.qcow2";
            varsTemplate = "${pkgs.OVMF.fd}/FV/OVMF_VARS.fd";
            qemuCommand = ''
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
          };

        # devbox-arm on Apple silicon. accel=hvf with -cpu host is real
        # hardware virtualisation, so the guest runs at native speed - the
        # whole point of building an ARM image rather than emulating the
        # x86 one.
        aarch64-darwin.devbox-qemu =
          let
            pkgs = nixpkgs.legacyPackages.aarch64-darwin;
            # qemu ships the ARM edk2 build itself, both blobs already padded
            # to the 64M that the virt machine's pflash wants, so there is no
            # separate OVMF package to chase on darwin.
            firmware = "${pkgs.qemu}/share/qemu";
          in
          mkDevboxQemuApp {
            inherit pkgs;
            inherit (pkgs) qemu;
            imageFile = "${self.packages.aarch64-linux.devbox-qemu}/${devboxQemuImageArm.config.image.filePath}";
            defaultDisk = "qemu/devbox-arm.qcow2";
            varsTemplate = "${firmware}/edk2-arm-vars.fd";
            qemuCommand = ''
              # virt has no VGA, so virtio-gpu-pci rather than virtio-vga. There
              # is no GPU passthrough either way - sway lands on llvmpipe.
              exec ${pkgs.qemu}/bin/qemu-system-aarch64 \
                -machine virt,accel=hvf -cpu host -smp 4 -m 8G \
                -drive if=pflash,format=raw,unit=0,readonly=on,file=${firmware}/edk2-aarch64-code.fd \
                -drive if=pflash,format=raw,unit=1,file="$vars" \
                -drive file="$disk",format=qcow2,if=virtio \
                -netdev user,id=net0,hostfwd=tcp::2222-:22 \
                -device virtio-net-pci,netdev=net0 \
                -device virtio-gpu-pci -display "''${DEVBOX_QEMU_DISPLAY:-cocoa}" \
                ''${QEMU_OPTS:-}
            '';
          };

        # The x86_64 image on Apple silicon. No hardware acceleration exists for
        # a cross-architecture guest, so this is full TCG emulation and is slow -
        # fine over ssh, rough for sway. It is a stopgap; devbox-qemu (the ARM
        # image) is the fast path. Nix will not build the x86_64 image on a Mac
        # either, so the image has to be copied in from a Linux builder first.
        aarch64-darwin.devbox-qemu-x86 =
          let
            pkgs = nixpkgs.legacyPackages.aarch64-darwin;
            firmware = "${pkgs.qemu}/share/qemu";
          in
          mkDevboxQemuApp {
            inherit pkgs;
            inherit (pkgs) qemu;
            # A plain path, not the store path: interpolating the latter would
            # make the image a build input of this script, and a Mac cannot
            # build a Linux image - `nix run` would try, and fail, before it
            # ever got to booting anything. Relative to the working directory,
            # like defaultDisk. Override with DEVBOX_QEMU_IMAGE.
            imageFile = "qemu/devbox_1.raw";
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
