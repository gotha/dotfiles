{
  pkgs,
  stablePkgs,
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
  systemPackages = import ../../config/packages.nix { pkgs = pkgs; };
in
{

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  _module.args = {
    username = cfg.username;
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
  ];

  # Override fonts to save disk space (bae doesn't need GUI fonts)
  fonts.packages = [ ];

  environment = {
    shells = with pkgs; [
      bash
      zsh
    ];
    systemPackages = systemPackages;
  };

  programs = {
    gnupg.agent.enable = true;
    zsh.enable = true;
  };

  services = {
    openssh.enable = true;
  };

  system.stateVersion = "25.05";

}
