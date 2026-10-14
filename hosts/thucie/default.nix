{ username, ... }:
let
  wireguard = import ../../config/wireguard.nix;
in
{
  _module.args = {
    inherit wireguard;
  };

  imports = [
    ./hardware-configuration.nix
    ./wireguard.nix
  ];

  home-manager.users.${username} = {
    imports = [ ../../home-manager/alacritty ];
    programs.sway.custom.terminal = "alacritty";
  };

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
  };

  networking = {
    hostName = "thucie";
    networkmanager.enable = true;
  };
}
