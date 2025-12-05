{ pkgs, sops-nix, stablePkgs, ... }:
let
  cfg = import ../../config/default.nix;
  userPackages = import ../../config/packages-user.nix { inherit pkgs stablePkgs; };
  linuxUserPackages = import ../../os/linux/packages-user.nix { inherit pkgs; };
  systemPackages = import ../../config/packages.nix { inherit pkgs; };
  #wallpaperPkg = pkgs.callPackage ../../wallpaper { };
in {

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  _module.args = {
    username = cfg.username;
    userPackages = userPackages ++ linuxUserPackages;
  };

  # @todo - maybe split nixos config into a separate distro
  imports = [
    ../../os/default.nix
    ../../os/nixos/bootloader.nix
    ../../os/nixos/gc.nix
    ../../os/nixos/trustme.nix
    ../../os/nixos/unfree.nix
    ../../os/linux/virt.nix
    ../../os/linux/user.nix
    {
      home-manager = {
        # @todo - maybe make waybar, mako, rofi, etc become deps of sway
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = { inputs = { inherit sops-nix; }; };
        users.${cfg.username}.imports = [
          ../../home-manager
          ../../home-manager/alacritty
          ../../home-manager/git
          ../../home-manager/mako
          ../../home-manager/mcp
          ../../home-manager/npm
          ../../home-manager/nvim
          ../../home-manager/rofi
          ../../home-manager/sops
          ../../home-manager/sway
          ../../home-manager/tmux
          ../../home-manager/vale
          ../../home-manager/waybar
          ../../home-manager/zsh
        ];
      };
    }
  ];

  environment = {
    shells = with pkgs; [ bash zsh ];
    systemPackages = systemPackages;
  };

  programs = {
    _1password.enable = true;
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "${cfg.username}" ];
    };
    firefox.enable = true;
    gnupg.agent.enable = true;
    obs-studio = {
      enable = true;
      plugins = with pkgs.obs-studio-plugins; [
        wlrobs
        obs-backgroundremoval
        obs-pipewire-audio-capture
        obs-gstreamer
        obs-vkcapture
      ];
    };
    #regreet = {
    #  enable = true;
    #  settings = {
    #    background = {
    #      path =
    #        "${wallpaperPkg}/nix-wallpaper-nineish-catppuccin-macchiato.png";
    #      fit = "Cover";
    #    };
    #    GTK = { application_prefer_dark_theme = true; };
    #    appearance = { greeting_msg = "Mr. Anderson, Welcome back!"; };
    #  };
    #};
    steam.enable = true;
    sway.enable = true;
    virt-manager.enable = true;
    zsh.enable = true;
  };

  # recommended so PipeWire gets realtime priority
  security.rtkit.enable = true;

  services = {
    blueman.enable = true;
    gnome.gnome-keyring.enable = true;
    libinput.enable = true;
    openssh.enable = true;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };
    greetd = {
      enable = true;
      settings = {
        default_session = {
          command =
            "${pkgs.tuigreet}/bin/tuigreet --time --cmd 'sway --unsupported-gpu'";
          user = "${cfg.username}";
        };
      };
    };
    upower.enable = true;
  };

  # Enable lingering for the ${cfg.username} user so the service starts at boot
  # even when the user is not logged in
  systemd.user.services."user@${cfg.username}".enable = true;

  xdg.portal.enable = true;

  system.stateVersion = "25.05";

}
