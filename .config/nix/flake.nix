{
  description = "my minimal flake";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = inputs@{ nixpkgs, darwin, nix-index-database, ... }: {
    darwinConfigurations.platypus = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      pkgs = import nixpkgs { system = "aarch64-darwin"; };
      modules = [ ./modules/darwin ];
    };

    darwinConfigurations."D2Y6PH4TGJ-Hristo-Georgiev" =
      darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        pkgs = import nixpkgs { system = "aarch64-darwin"; };
        modules = [ ./modules/darwin ];
      };

    nixosConfigurations.thucie = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./modules/thucie nix-index-database.nixosModules.nix-index ];
    };
  };
}
