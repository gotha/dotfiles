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
                prev.lib.optionalAttrs prev.stdenv.isDarwin {
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
          devbox-qemu =
            let
              config = nixpkgs.lib.nixosSystem {
                system = "x86_64-linux";
                modules = distro.devbox ++ [
                  ./hosts/qemu1
                  ./os/linux/virtio.nix
                ];
                specialArgs = { inherit sops-nix; };
              };
            in
            config.config.system.build.images.qemu;
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
        deploy-devbox-qemu = {
          type = "app";
          meta.description = "Deploy the devbox QEMU NixOS configuration";
          program = toString (
            nixpkgs.legacyPackages.x86_64-linux.writeScript "deploy-devbox-qemu" ''
              #!/usr/bin/env bash
              nixos-rebuild switch --flake .#devbox --target-host devbox.qemu --use-remote-sudo
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
