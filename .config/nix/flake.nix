{
  description = "my minimal flake";
  inputs = {
    # Where we get most of our software. Giant mono repo with recipes
    # called derivations that say how to build software.
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable"; 

    # Manages configs links things into your home directory
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Controls system level software and settings including fonts
    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = inputs@{ nixpkgs, home-manager, darwin, ... }: {
    darwinConfigurations.FT-MW1221 = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      pkgs = import nixpkgs { system = "aarch64-darwin"; };
      modules = [
        ./modules/darwin
        home-manager.darwinModules.home-manager
	{
          users.users."hristo.georgiev".home = "/Users/hristo.georgiev";
        }
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users."hristo.georgiev".imports = [ ./modules/home-manager ];
          };
        }
      ];
    };
  };
}
