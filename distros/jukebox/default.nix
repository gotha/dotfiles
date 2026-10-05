# jukebox: a NixOS appliance whose entire user interface is Kodi.
#
# Deliberately board-neutral. Everything here holds on a Raspberry Pi, an x86
# home theatre PC or a VM; anything that knows about one particular machine -
# the kernel, the device tree, config.txt, how the disk is laid out - belongs
# in the host instead. hosts/pizzie is the Raspberry Pi 3 Model B this was
# written for.
#
# Closest sibling is distros/bae: the same minimal headless base, the same
# home-manager subset, the same journald caps. What jukebox adds is ./kodi.nix.
{
  lib,
  pkgs,
  sops-nix,
  ...
}:
let
  cfg = import ../../config/default.nix;
  minimalUserPackages = with pkgs; [
    bc
    tmux
    neovim
    ncdu
    nixd
    sops
  ];
  systemPackages = import ../../config/packages.nix { inherit pkgs; };
in
{

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  _module.args = {
    inherit (cfg) username;
    userPackages = minimalUserPackages;
  };

  imports = [
    ./kodi.nix
    ./iptv.nix
    ../../os/default.nix
    ../../os/nixos/bootloader.nix
    ../../os/nixos/gc.nix
    ../../os/nixos/unfree.nix
    ../../os/linux/user.nix
    sops-nix.nixosModules.sops
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = {
          inputs = { inherit sops-nix; };
        };
        users.${cfg.username}.imports = [
          ../../home-manager
          ../../home-manager/zsh
        ];
      };
    }
  ];

  # The only thing with a screen here is Kodi, and a Kodi skin carries the
  # fonts it draws with inside its own package. config/fonts.nix is six nerd
  # font families for terminal emulators this machine never runs.
  fonts.packages = lib.mkForce [ ];

  # An appliance running off an SD card, where the journal is the write the
  # card is most likely to die of. Same caps bae uses on its small droplet.
  services.journald.settings.Journal = {
    SystemMaxUse = "100M";
    SystemMaxFileSize = "50M";
    MaxRetentionSec = "7day";
  };

  # Allow user to push closures via deploy-rs
  nix.settings.trusted-users = [
    "root"
    cfg.username
  ];

  environment = {
    shells = with pkgs; [
      zsh
    ];
    inherit systemPackages;
  };

  programs = {
    zsh.enable = true;
  };

  # A TV box sits wherever the TV is, which is rarely next to a switch.
  # NetworkManager covers wired and wireless without either being declared
  # here, and os/linux/user.nix already puts the user in the networkmanager
  # group, so joining a network is `nmtui` over ssh. First boot still wants
  # ethernet: there is no keyboard on this thing, and no way in before it has
  # an address.
  networking.networkmanager.enable = true;

  services = {
    openssh.enable = true;
  };

  # Newer than the 25.05 bae and devbox carry, because no machine has ever been
  # installed from this distro before. The value records the release a machine
  # was first installed from, so a new one starts at the current release and is
  # then never moved again.
  system.stateVersion = "26.11";

}
