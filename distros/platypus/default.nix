{ config, lib, pkgs, sops-nix, ... }:
let
  cfg = import ../../config/default.nix;
  userPackages = import ../../config/packages-user.nix { inherit pkgs; };
  systemPackages = import ../../config/packages.nix { inherit pkgs; };
  darwinUserPackages =
    import ../../os/darwin/packages-user.nix { inherit pkgs; };
in {

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  _module.args = {
    username = cfg.username;
    systemPackages = systemPackages;
  };

  imports = [
    ../../os/default.nix
    ../../os/darwin/homebrew.nix
    ../../os/darwin/system.nix
    {
      users.users.${cfg.username} = {
        home = "/Users/${cfg.username}";
        packages = userPackages ++ darwinUserPackages;
      };
    }
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = { inputs = { inherit sops-nix; }; };
        users.${cfg.username} = {
          imports = [
            ../../home-manager
            ../../home-manager/aerospace
            ../../home-manager/alacritty
            ../../home-manager/git
            ../../home-manager/npm
            ../../home-manager/nvim
            ../../home-manager/sketchybar
            ../../home-manager/sops
            ../../home-manager/vscode
            ../../home-manager/vale
            ../../home-manager/tmux
            ../../home-manager/zsh
            ../../os/darwin/home-manager/ollama
          ];
          programs.alacritty.custom.fontSize = 11.0;
        };
      };

    }
  ];

}
