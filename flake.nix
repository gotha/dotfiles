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
      distro = {
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
      devboxQemuImage = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = distro.devbox ++ [
          ./os/linux/virtio.nix
          ./os/linux/repart-image.nix
        ];
        specialArgs = { inherit sops-nix; };
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

      apps.x86_64-linux = {
        devbox-qemu =
          let
            pkgs = nixpkgs.legacyPackages.x86_64-linux;
            image = self.packages.x86_64-linux.devbox-qemu;
            imageFile = "${image}/${devboxQemuImage.config.image.filePath}";
          in
          {
            type = "app";
            meta.description = "Boot the self-contained devbox image in a QEMU VM";
            program = toString (
              pkgs.writeShellScript "devbox-qemu" ''
                set -euo pipefail

                disk="''${DEVBOX_QEMU_DISK:-qemu/devbox.qcow2}"
                vars="''${disk%.qcow2}-efivars.fd"
                if [ "''${1-}" = "--fresh" ]; then
                  rm -f "$disk" "$vars"
                fi

                # The overlay is only valid for the exact image it was created
                # from, so a disk left behind by an older build has to go. Left
                # in place it either boots the previous image, breaks once that
                # store path is garbage collected, or - if it predates this
                # setup and has no ESP at all - dies in OVMF with
                # "BdsDxe: failed to load Boot0002 ... Not Found".
                if [ -e "$disk" ]; then
                  backing=$(${pkgs.qemu_kvm}/bin/qemu-img info --output=json "$disk" \
                    | ${pkgs.jq}/bin/jq -r '."backing-filename" // ""')
                  if [ "$backing" != "${imageFile}" ]; then
                    echo "devbox-qemu: $disk was built from a different image, recreating it" >&2
                    echo "devbox-qemu:   had: ''${backing:-(none)}" >&2
                    echo "devbox-qemu:   now: ${imageFile}" >&2
                    rm -f "$disk" "$vars"
                  fi
                fi

                # Back a writable qcow2 onto the image rather than copying 47G.
                if [ ! -e "$disk" ]; then
                  mkdir -p "$(dirname "$disk")"
                  ${pkgs.qemu_kvm}/bin/qemu-img create -f qcow2 \
                    -b ${imageFile} -F raw "$disk" >/dev/null
                fi
                # OVMF needs its own writable copy of the variable store.
                if [ ! -e "$vars" ]; then
                  install -Dm600 ${pkgs.OVMF.fd}/FV/OVMF_VARS.fd "$vars"
                fi

                # UEFI, not BIOS: the image boots a UKI from its ESP.
                # DEVBOX_QEMU_DISPLAY=none plus QEMU_OPTS='-serial stdio' runs it
                # headless, which is the only way to see the boot at all.
                exec ${pkgs.qemu_kvm}/bin/qemu-system-x86_64 \
                  -machine q35 -enable-kvm -cpu host -smp 4 -m 8G \
                  -drive if=pflash,format=raw,unit=0,readonly=on,file=${pkgs.OVMF.fd}/FV/OVMF_CODE.fd \
                  -drive if=pflash,format=raw,unit=1,file="$vars" \
                  -drive file="$disk",format=qcow2,if=virtio \
                  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
                  -device virtio-net-pci,netdev=net0 \
                  -device virtio-vga -display "''${DEVBOX_QEMU_DISPLAY:-gtk}" \
                  ''${QEMU_OPTS:-}
              ''
            );
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
