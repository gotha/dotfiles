{
  description = "my minimal flake";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
  };
  outputs = inputs@{ nixpkgs, darwin, nix-index-database, home-manager
    , nix-vscode-extensions, ... }:
    let
      configuration = { pkgs, ... }: {
        nixpkgs.overlays = [ nix-vscode-extensions.overlays.default ];
      };
    in {
      darwinConfigurations.platypus = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [ ./modules/darwin ];
      };

      darwinConfigurations."D2Y6PH4TGJ-Hristo-Georgiev" =
        darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          modules = [
            configuration
            ./modules/darwin
            home-manager.darwinModules.home-manager
            { users.users.gotha.home = "/Users/gotha"; }
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.gotha.imports = [ ./modules/home-manager ];
              };
            }
          ];
        };

      nixosConfigurations.thucie = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules =
          [ ./modules/thucie nix-index-database.nixosModules.nix-index ];
      };
    };
}
