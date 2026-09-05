{
  pkgs,
  stablePkgs,
  username,
  lib,
  config,
  ...
}:
let
  wireguard = import ../../config/wireguard.nix;
  keydSymbols = import ../../config/keyd-symbols.nix;
  symbolLayer = config.services.keyd.custom.symbolLayer.enable;
in
{

  _module.args = {
    inherit wireguard;
  };

  imports = [
    ./hardware-configuration.nix
    ./litellm.nix
    ./nextcloud.nix
    ./nightly-build.nix
    ./observability.nix
    ./tunnels.nix
    ./wireguard.nix
    ../../os/linux/efi.nix
  ];

  # Binary cache for the nixpkgs-ruby flake (prebuilt Ruby versions).
  nix.settings = {
    extra-substituters = [ "https://nixpkgs-ruby.cachix.org" ];
    extra-trusted-public-keys = [
      "nixpkgs-ruby.cachix.org-1:vrcdi50fTolOxWCZZkw0jakOnUI1T19oYJ+PRYdK4SM="
    ];
  };

  # aarch64 emulation, so this x86_64 box can build the devbox-arm image for
  # the mac. Registers the binfmt handlers and adds aarch64-linux to nix.conf's
  # extra-platforms, which is what lets nix build aarch64 derivations here.
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # Cap dirty page cache in absolute terms rather than as a share of RAM. The
  # default vm.dirty_ratio = 20 lets a single writer accumulate ~12 GB of dirty
  # pages on this 62 GB box, which is how the 2026-08-28 nightly build stalled
  # the ext4 journal: jbd2 sat in jbd2_journal_wait_updates for minutes at a
  # time and every other writer piled up behind it. Setting the _bytes knobs
  # zeroes their _ratio counterparts, which is intended.
  boot.kernel.sysctl = {
    "vm.dirty_background_bytes" = 512 * 1024 * 1024; # start writeback at 512 MB
    "vm.dirty_bytes" = 2 * 1024 * 1024 * 1024; # block the writer at 2 GB
  };

  networking = {
    hostName = "lucie";

    networkmanager.enable = true; # Easiest to use and most distros use this by default.

    # Configure firewall for Twingate and WireGuard
    firewall = {
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
  };

  users.users.${username}.packages = with pkgs; [
    jellyfin
    jellyfin-web
    jellyfin-ffmpeg
    transmission_4-gtk
  ];

  # Disable MCP servers that are unreachable without VPN.
  home-manager.users.${username}.programs.mcp = {
    enableAtlassian = false;
    enableAsana = false;
    enableCircleci = false;
    enableGcloud = false;
    enableGrafana = false;
    enableTempo = false;
  };

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

  environment = {
    # Make nvidia-container-cli and CUDA toolkit available system-wide
    systemPackages = with pkgs; [
      libnvidia-container
      cudaPackages.cudatoolkit
    ];

    variables.EDITOR = "vim";

    # Bluetooth: disable LDAC (decoder has issues), use aptX HD as default
    etc."wireplumber/wireplumber.conf.d/51-disable-ldac.conf".text = ''
      monitor.bluez.properties = {
        bluez5.codecs = [ aptx_hd aptx aac sbc_xq sbc ]
      }
    '';
  };

  services = {
    # Enable dictation with CUDA-accelerated whisper (NVIDIA GPU).
    # server.enable keeps the model resident in VRAM so dictation doesn't race
    # ollama for a transient allocation (which intermittently OOM'd).
    dictation = {
      enable = true;
      pauseMusic = true; # instead of just lowering the volume while talking
      model = "small";
      whisperPackage = stablePkgs.whisper-cpp.override { cudaSupport = true; };
      server.enable = true;
    };

    # No hold-Space symbol layer on this host.
    keyd.custom.symbolLayer.enable = false;
    keyd.keyboards = {
      keychron = {
        ids = [ "3434:0260" ];
        settings = {
          main = {
            capslock = "overload(control, esc)";
            esc = "grave";
          }
          // lib.optionalAttrs symbolLayer { space = keydSymbols.mainSpace; };
        }
        // lib.optionalAttrs symbolLayer keydSymbols.extraSections;
      };
      ducky = {
        ids = [ "0416:0123" ];
        settings = {
          main = {
            capslock = "overload(control, esc)";
            esc = "grave";
          }
          // lib.optionalAttrs symbolLayer { space = keydSymbols.mainSpace; };
          shift.delete = "insert";
        }
        // lib.optionalAttrs symbolLayer keydSymbols.extraSections;
      };
    };

    jellyfin = {
      enable = true;
      openFirewall = true;
    };

    mpd.settings.music_directory = lib.mkForce "/mnt/storage/Music";

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
        # Handle up to 4 concurrent requests per model instead of the default 1.
        OLLAMA_NUM_PARALLEL = "1";
        OLLAMA_KEEP_ALIVE = "24h";
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
