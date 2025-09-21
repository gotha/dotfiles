{ pkgs, ... }:
let
  cfg = import ../../config/default.nix;
  userPackages = import ../../config/packages-user.nix { pkgs = pkgs; };
  systemPackages = import ../../config/packages.nix { pkgs = pkgs; };
in {

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  _module.args = {
    username = cfg.username;
    userPackages = userPackages;
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
        users.${cfg.username}.imports = [
          ../../home-manager
          ../../home-manager/alacritty
          ../../home-manager/rofi
          ../../home-manager/sway
          ../../home-manager/tmux
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
    upower.enable = true;
  };

  xdg.portal.enable = true;

  system.stateVersion = "25.05";

}
