{ pkgs, username, lib, ... }:
let wireguard = import ../../config/wireguard.nix;
in {

  _module.args = { wireguard = wireguard; };

  imports = [
    ./hardware-configuration.nix
    ./nextcloud.nix
    ./tunnels.nix
    ./wireguard.nix
    ../../os/linux/efi.nix
  ];

  networking.hostName = "lucie";

  networking.networkmanager.enable =
    true; # Easiest to use and most distros use this by default.

  # Configure firewall for Twingate and WireGuard
  networking.firewall = {
    # Twingate creates its own network interface and needs to bypass some firewall checks
    checkReversePath = "loose";
    # Allow Twingate to communicate (it uses dynamic ports)
    # Allow WireGuard peers to access all ports
    trustedInterfaces = [ "tun-twingate" "wg0" ];
    # Allow WireGuard port from public internet
    allowedUDPPorts = [ 51820 ];
  };

  users.users.${username}.packages = with pkgs; [
    jellyfin
    jellyfin-web
    jellyfin-ffmpeg
    ollama-cuda
    transmission_4-gtk
  ];

  # Configure Docker
  virtualisation.docker = {
    daemon.settings = {
      # Enable CDI for GPU access (modern approach, replaces nvidia-docker)
      features = { cdi = true; };
    };
  };

  systemd.services.docker = { path = with pkgs; [ runc libnvidia-container ]; };

  # Make nvidia-container-cli available system-wide
  environment.systemPackages = with pkgs; [ libnvidia-container ];

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
      openFirewall = true;
    };

    open-webui = {
      enable = true;
      package = pkgs.open-webui;
      host = "0.0.0.0";
      port = 11435;
      openFirewall = true;
    };

    plex = {
      enable = true;
      openFirewall = true;
      user = username;
    };

    twingate = {
      enable = true;
    };

    xserver.videoDrivers = [ "nvidia" ];

    nix-serve = {
      enable = true;
      package = pkgs.nix-serve-ng;
      secretKeyFile = "/var/secrets/cache-private-key.pem";
      openFirewall = true;
    };
  };

  home-manager.users.${username} = {
    programs = {
      mcp = {
        # Disable GitHub MCP server for lucie because it does not currently work for linux
        enableGithub = false;
        # tempo and grafana servers require vpn that is not supported by this config yet
        enableTempo = false;
        enableGrafana = false;
      };
    };
  };

}
