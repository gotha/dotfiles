{ pkgs, stablePkgs, sops-nix, ... }:
let
  cfg = import ../../config/default.nix;
  userPackages =
    import ../../config/packages-user.nix { inherit pkgs stablePkgs; };
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
    ../../os/nixos/unfree.nix
    ../../os/linux/virt.nix
    ../../os/linux/user.nix
    sops-nix.nixosModules.sops
  ];

  environment = {
    shells = with pkgs; [ bash zsh ];
    systemPackages = systemPackages;
  };

  programs = {
    gnupg.agent.enable = true;
    zsh.enable = true;
  };

  # recommended so PipeWire gets realtime priority
  security.rtkit.enable = true;

  services = {
    gnome.gnome-keyring.enable = true;
    libinput.enable = true;
    openssh.enable = true;
    upower.enable = true;
  };

  system.stateVersion = "25.05";

}
