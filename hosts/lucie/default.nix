{
  pkgs,
  stablePkgs,
  username,
  lib,
  ...
}:
let
  wireguard = import ../../config/wireguard.nix;
in
{

  _module.args = {
    wireguard = wireguard;
  };

  imports = [
    ./hardware-configuration.nix
    ./litellm.nix
    ./nextcloud.nix
    ./nightly-build.nix
    ./tunnels.nix
    ./wireguard.nix
    ../../os/linux/efi.nix
  ];

  networking.hostName = "lucie";

  # Enable dictation with CUDA-accelerated whisper (NVIDIA GPU)
  services.dictation = {
    enable = true;
    model = "small";
    whisperPackage = stablePkgs.whisper-cpp.override { cudaSupport = true; };
  };

  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.

  # Configure firewall for Twingate and WireGuard
  networking.firewall = {
    # Twingate creates its own network interface and needs to bypass some firewall checks
    checkReversePath = "loose";
    # Allow Twingate to communicate (it uses dynamic ports)
    # Allow WireGuard peers to access all ports
    trustedInterfaces = [
      "tun-twingate"
      "wg0"
    ];
    # Allow WireGuard port from public internet
    allowedUDPPorts = [ 51820 ];
  };

  users.users.${username}.packages = with pkgs; [
    jellyfin
    jellyfin-web
    jellyfin-ffmpeg
    transmission_4-gtk
  ];

  # Configure Docker
  virtualisation.docker = {
    daemon.settings = {
      # Enable CDI for GPU access (modern approach, replaces nvidia-docker)
      features = {
        cdi = true;
      };
    };
  };

  systemd.services.docker = {
    path = with pkgs; [
      runc
      libnvidia-container
    ];
  };

  # Make nvidia-container-cli and CUDA toolkit available system-wide
  environment.systemPackages = with pkgs; [
    libnvidia-container
    cudaPackages.cudatoolkit
  ];

  # Bluetooth: disable LDAC (decoder has issues), use aptX HD as default
  environment.etc."wireplumber/wireplumber.conf.d/51-disable-ldac.conf".text = ''
    monitor.bluez.properties = {
      bluez5.codecs = [ aptx_hd aptx aac sbc_xq sbc ]
    }
  '';

  services = {
    jellyfin = {
      enable = true;
      openFirewall = true;
    };

    mpd.musicDirectory = lib.mkForce "/mnt/storage/Music";

    ollama = {
      enable = true;
      package = pkgs.ollama-cuda;
      host = "0.0.0.0";
      port = 11434;
      openFirewall = true;
      environmentVariables = {
        # Flash attention is a prerequisite for KV cache quantization.
        # q8_0 halves KV cache VRAM with negligible quality impact.
        OLLAMA_FLASH_ATTENTION = "1";
        OLLAMA_KV_CACHE_TYPE = "q8_0";
        # Only keep one model resident to guarantee full GPU residency for the
        # active model (no layer split across CPU/GPU when switching models).
        OLLAMA_MAX_LOADED_MODELS = "1";
        # Default context window bumped from 32k to 64k. With q8_0 KV cache
        # and flash attention, gemma4:31b + 64k cache fits on the 32 GB RTX 5090.
        OLLAMA_CONTEXT_LENGTH = "65536";
      };
    };

    # TODO: temporarily disabled due to flaky psycopg test in nixpkgs
    # open-webui = {
    #   enable = true;
    #   package = pkgs.open-webui;
    #   host = "0.0.0.0";
    #   port = 11435;
    #   openFirewall = true;
    # };

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

}
