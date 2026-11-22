{
  pkgs,
  sops-nix,
  stablePkgs,
  ...
}:
let
  cfg = import ../../config/default.nix;
  userPackages = import ../../config/packages-user.nix { inherit pkgs stablePkgs; };
  linuxUserPackages = import ../../os/linux/packages-user.nix { inherit pkgs; };
  systemPackages = import ../../config/packages.nix { inherit pkgs; };
  #wallpaperPkg = pkgs.callPackage ../../wallpaper { };
in
{

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  _module.args = {
    inherit (cfg) username;
    userPackages = userPackages ++ linuxUserPackages;
  };

  # @todo - maybe split nixos config into a separate distro
  imports = [
    ./dictation.nix
    ../../os/default.nix
    ../../os/nixos/bootloader.nix
    ../../os/nixos/gc.nix
    ../../os/nixos/trustme.nix
    ../../os/nixos/unfree.nix
    ../../os/nixos/services/audio.nix
    ../../os/nixos/services/greetd.nix
    ../../os/nixos/services/keyd.nix
    ../../os/nixos/services/mpd.nix
    ../../os/nixos/services/transmission.nix
    ../../os/linux/virt.nix
    ../../os/linux/user.nix
    ../../os/linux/zsa.nix
    {
      home-manager = {
        # @todo - maybe make waybar, mako, rofi, etc become deps of sway
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = {
          inputs = { inherit sops-nix; };
        };
        users.${cfg.username} = {
          # The policies and force-installed extensions the NixOS firefox module
          # used to write to /etc/firefox/policies. Opt-in, so a host can have
          # plain firefox.
          programs.firefox.custom.policies.enable = true;

          imports = [
            ../../home-manager
            ../../home-manager/aerc
            ../../home-manager/claude-code
            ../../home-manager/codex
            ../../home-manager/crush
            ../../home-manager/cursor-cli
            ../../home-manager/kitty
            ../../home-manager/firefox
            ../../home-manager/git
            ../../home-manager/mako
            ../../home-manager/mcp
            ../../home-manager/mpd
            ../../home-manager/nextcloud-sync
            ../../home-manager/nodejs
            ../../home-manager/nvim
            ../../home-manager/opencode
            ../../home-manager/rofi
            ../../home-manager/sops
            ../../home-manager/ssh
            ../../home-manager/swayfx
            ../../home-manager/tmux
            ../../home-manager/vale
            ../../home-manager/waybar
            ../../home-manager/zsh
          ];
        };
      };
    }
  ];

  environment = {
    shells = with pkgs; [
      bash
      zsh
    ];
    inherit systemPackages;
  };

  programs = {
    _1password.enable = true;
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "${cfg.username}" ];
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
    sway.enable = true;
    virt-manager.enable = true;
    zsh.enable = true;
  };

  services = {
    blueman.enable = true;
    gnome.gnome-keyring.enable = true;

    # Straight to sway rather than the picker: devbox has the one session, and
    # --unsupported-gpu keeps wlroots quiet on the hosts with an nvidia card.
    greetd.custom.defaultSession = "sway --unsupported-gpu";

    libinput.enable = true;
    openssh.enable = true;
    upower.enable = true;
  };

  systemd = {
    # Enable lingering for the ${cfg.username} user so the service starts at boot
    # even when the user is not logged in
    user.services."user@${cfg.username}".enable = true;
  };

  xdg.portal.enable = true;

  system.stateVersion = "26.05";

}
