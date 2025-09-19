{ pkgs, ... }:
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
    ../../os/darwin/services.nix
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
        users.${cfg.username}.imports =
          [ ../../home-manager ../../home-manager/vscode.nix ];
      };
    }
  ];
}
