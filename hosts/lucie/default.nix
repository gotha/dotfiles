{ pkgs, username, lib, ... }:
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

  # Configure system to use dnsmasq for DNS resolution
  networking.nameservers = [ "127.0.0.1" ];

  users.users.${username}.packages = with pkgs; [
    jellyfin
    jellyfin-web
    jellyfin-ffmpeg
    ollama-cuda
    transmission_4-gtk
  ];

  # Configure Docker for Harbor (local k3s registry)
  # Use rootful Docker instead of rootless
  # Harbor is accessible at harbor.local via dnsmasq DNS resolution
  virtualisation.docker = {
    daemon.settings = {
      # Allow insecure registries for local development
      insecure-registries = [ "harbor.local" ];
      # Enable CDI for GPU access (modern approach, replaces nvidia-docker)
      features = { cdi = true; };
    };
  };

  systemd.services.docker = { path = with pkgs; [ runc libnvidia-container ]; };

  # Make nvidia-container-cli available system-wide
  environment.systemPackages = with pkgs; [ libnvidia-container ];

  services = {
    # Local DNS server for resolving k3s services
    dnsmasq = {
      enable = true;
      settings = {
        # Listen on localhost only
        listen-address = "127.0.0.1";

        # Only bind to specified interfaces (prevents conflict with libvirt dnsmasq)
        bind-interfaces = true;

        # Don't read /etc/resolv.conf (we'll specify upstream DNS manually)
        no-resolv = true;

        # Forward all other queries to router and Google DNS
        server = [ "192.168.1.1" "8.8.8.8" ];

        # Local domain resolution for k3s services
        address = [ "/harbor.local/192.168.1.12" "/argocd.local/192.168.1.12" ];
      };
    };

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

    xserver.videoDrivers = [ "nvidia" ];

    nix-serve = {
      enable = true;
      package = pkgs.nix-serve-ng;
      secretKeyFile = "/var/secrets/cache-private-key.pem";
      openFirewall = true;
    };
  };

  home-manager.users.${username} = {
    # Disable GitHub MCP server for lucie because it does not currently work for linux
    programs.mcp.enableGithub = false;
  };

}
