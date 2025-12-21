{ pkgs, username, ... }:
let wireguard = import ../../config/wireguard.nix;
in {

  _module.args = { wireguard = wireguard; };

  imports = [
    ./hardware-configuration.nix
    ./k3s.nix
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
    ollama-cuda
    transmission_4-gtk
  ];

  services = {

    jellyfin = {
      enable = true;
      openFirewall = true;
    };

    ollama = {
      enable = true;
      package = pkgs.ollama-cuda;
      # Optional: specify which GPU to use (default is all available)
      # environmentVariables = {
      #   CUDA_VISIBLE_DEVICES = "0";
      # };
      host = "0.0.0.0";
      port = 11434;
    };

    plex = {
      enable = true;
      openFirewall = true;
      user = username;
    };

    xserver.videoDrivers = [ "nvidia" ];

    nix-serve = {
      enable = true;
      package = pkgs.nix-serve-ng;
      secretKeyFile = "/var/secrets/cache-private-key.pem";
      openFirewall = true;
    };
  };

}
