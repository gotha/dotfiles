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

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy-rs.url = "github:serokell/deploy-rs";

    gotha.url = "github:gotha/nixpkgs?ref=main";
  };
  outputs = { self, nixpkgs, nixpkgs-stable, darwin, nix-index-database
    , nixos-generators, home-manager, nix-vscode-extensions, sops-nix, gotha
    , deploy-rs, ... }:
    let
      configuration = { pkgs, ... }: {
        nixpkgs.overlays =
          [ nix-vscode-extensions.overlays.default gotha.overlays.default ];
        _module.args.stablePkgs = import nixpkgs-stable {
          system = pkgs.system;
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
        ];
        platypus = [
          configuration
          ./distros/platypus
          nix-index-database.darwinModules.nix-index
          home-manager.darwinModules.home-manager
          sops-nix.darwinModules.sops
          ({ ... }: { nix.enable = false; })
        ];
      };
      wireguard = import ./config/wireguard.nix;
    in {

      darwinConfigurations = {
        "D2Y6PH4TGJ-Hristo-Georgiev" = darwin.lib.darwinSystem {
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
          modules = distro.devbox ++ [ ./hosts/qemu1 ./os/linux/virtio.nix ];
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
          bae-qemu = nixos-generators.nixosGenerate {
            system = "x86_64-linux";
            format = "raw";
            modules = distro.bae ++ [ ./hosts/qemu1 ./os/linux/virtio.nix ];
            specialArgs = { inherit sops-nix; };
          };
          devbox-qemu = nixos-generators.nixosGenerate {
            system = "x86_64-linux";
            format = "raw";
            modules = distro.devbox ++ [ ./hosts/qemu1 ./os/linux/virtio.nix ];
            specialArgs = { inherit sops-nix; };
          };
        };
      };

      apps.x86_64-linux = {
        deploy-devbox-qemu = {
          type = "app";
          program = toString (nixpkgs.legacyPackages.x86_64-linux.writeScript
            "deploy-devbox-qemu" ''
              #!/usr/bin/env bash
              nixos-rebuild switch --flake .#devbox --target-host devbox.qemu --use-remote-sudo
            '');
        };
      };

      devShells = {
        x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.mkShell {
          packages = with nixpkgs.legacyPackages.x86_64-linux; [ nixd ];
        };

        aarch64-darwin.default = nixpkgs.legacyPackages.aarch64-darwin.mkShell {
          packages = with nixpkgs.legacyPackages.aarch64-darwin; [ nixd ];
        };
      };

      deploy.nodes = {
        bastion = {
          hostname = wireguard.bastion.publicIP;
          remoteBuild = true;
          sshUser = wireguard.bastion.username;
          profiles.system = {
            user = "root";
            path = deploy-rs.lib.x86_64-linux.activate.nixos
              self.nixosConfigurations.bastion;
          };
        };
      };

      # This is highly advised, and will prevent many possible mistakes
      checks = builtins.mapAttrs
        (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };
}
