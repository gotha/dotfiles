{
  pkgs,
  sops-nix,
  stablePkgs,
  ...
}:
let
  cfg = import ../../config/default.nix;
  userPackages = import ../../config/packages-user.nix { inherit pkgs stablePkgs; };
  systemPackages = import ../../config/packages.nix { inherit pkgs; };
  darwinUserPackages = import ../../os/darwin/packages-user.nix { inherit pkgs; };
in
{

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  _module.args = {
    inherit (cfg) username;
    inherit systemPackages;
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
        backupFileExtension = "backup";
        extraSpecialArgs = {
          inputs = { inherit sops-nix; };
        };
        users.${cfg.username} = {
          imports = [
            ../../home-manager
            ../../home-manager/aerospace
            ../../home-manager/alacritty
            ../../home-manager/auggie
            ../../home-manager/claude-code
            ../../home-manager/codex
            ../../home-manager/crush
            ../../home-manager/cursor-cli
            ../../home-manager/git
            ../../home-manager/karabiner
            ../../home-manager/kitty
            ../../home-manager/mcp
            #../../home-manager/mpd
            ../../home-manager/nodejs
            ../../home-manager/nvim
            ../../home-manager/sketchybar
            ../../home-manager/sops
            # Disabled due to glibc dependency issue on Darwin
            # https://github.com/NixOS/nixpkgs/issues/272016
            # ../../home-manager/vscode
            ../../home-manager/vale
            ../../home-manager/tmux
            ../../home-manager/zsh
          ];
          programs = {
            alacritty.custom.fontSize = 11.0;
            kitty.custom = {
              fontSize = 11.0;
              fontFamily = "Iosevka Nerd Font";
            };
          };
        };
      };

    }
  ];

}
