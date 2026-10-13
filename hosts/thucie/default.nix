{ lib, ... }:
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

  # Installed from 24.11, before it was a devbox.
  system.stateVersion = lib.mkForce "24.11";
}
