{
  description = "my minimal flake";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

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
  };
  outputs = { nixpkgs, darwin, nix-index-database, nixos-generators
    , home-manager, nix-vscode-extensions, ... }:
    let
      configuration = { pkgs, ... }: {
        nixpkgs.overlays = [ nix-vscode-extensions.overlays.default ];
      };
      distro = {
        bae = [
          ./distros/bae
          nix-index-database.nixosModules.nix-index
          home-manager.nixosModules.home-manager
        ];
        devbox = [
          ./distros/devbox
          nix-index-database.nixosModules.nix-index
          home-manager.nixosModules.home-manager
        ];
        platypus = [
          configuration
          ./distros/platypus
          home-manager.darwinModules.home-manager
        ];
      };
    in {

      darwinConfigurations = {
        "D2Y6PH4TGJ-Hristo-Georgiev" = darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = distro.platypus;
        };
      };

      nixosConfigurations = {
        bae = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = distro.bae ++ [ ./hosts/qemu1 ];
        };
        devbox = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = distro.devbox ++ [ ./hosts/qemu1 ];
        };
        lucie = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = distro.devbox ++ [ ./hosts/lucie ];
        };
      };

      packages = {
        x86_64-linux = {
          bae-qemu = nixos-generators.nixosGenerate {
            system = "x86_64-linux";
            format = "raw";
            modules = distro.bae ++ [ ./hosts/qemu1 ./os/linux/virtio.nix ];
          };
          devbox-qemu = nixos-generators.nixosGenerate {
            system = "x86_64-linux";
            format = "raw";
            modules = distro.devbox ++ [ ./hosts/qemu1 ./os/linux/virtio.nix ];
          };
        };
      };

    };
}
