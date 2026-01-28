{ config, pkgs, ... }:

{
  imports = [
    ./digitalocean.nix
    ./nginx.nix
    ./wireguard.nix
  ];

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 4096; # Size in MB
    }
  ];

  networking.useDHCP = true;

  system.stateVersion = "25.05"; # Did you read the comment?
}
