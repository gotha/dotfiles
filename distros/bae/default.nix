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

  # @todo - maybe split nixos config into a separate distro
  imports = [
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
          ../../home-manager/git
          ../../home-manager/zsh
        ];
      };
    }
  ];

  # Override fonts to save disk space (bae doesn't need GUI fonts)
  fonts.packages = lib.mkForce [ ];

  # Limit journal size to save disk space
  services.journald.extraConfig = ''
    SystemMaxUse=100M
    SystemMaxFileSize=50M
    MaxRetentionSec=7day
  '';

  # Allow user to push closures via deploy-rs
  nix.settings.trusted-users = [
    "root"
    cfg.username
  ];

  environment = {
    shells = with pkgs; [
      bash
      zsh
    ];
    inherit systemPackages;
  };

  programs = {
    zsh.enable = true;
  };

  services = {
    openssh.enable = true;
  };

  system.stateVersion = "25.05";

}
