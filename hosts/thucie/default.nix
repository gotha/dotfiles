_:
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

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
  };

  networking = {
    hostName = "thucie";
    networkmanager.enable = true;
  };
}
