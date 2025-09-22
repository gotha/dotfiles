{ pkgs, username, ... }:
let wireguard = import ../../config/wireguard.nix;
in {

  _module.args = { wireguard = wireguard; };

  imports = [
    ./hardware-configuration.nix
    ./tunnels.nix
    ./wireguard.nix
    ../../os/linux/efi.nix
  ];

  networking.hostName = "lucie";

  networking.networkmanager.enable =
    true; # Easiest to use and most distros use this by default.

  users.users.${username}.packages = with pkgs; [
    jellyfin
    jellyfin-web
    jellyfin-ffmpeg
  ];

  services = { xserver.videoDrivers = [ "nvidia" ]; };

}
