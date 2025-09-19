{ lib, pkgs, ... }:
let
  cfg = import ../global/conf.nix;
  globalUserPackages = import ../global/packages-user.nix;
  systemPackages = import ../global/packages.nix;
  fonts = import ../global/fonts.nix;
in {

  networking.hostName = "lucie"; # Define your hostname.

  fonts.packages = fonts { pkgs = pkgs; };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  time.timeZone = cfg.timeZone;

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  services.libinput.enable = true;

  nixpkgs.config = {
    allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [
        "1password"
        "1password-cli"
        "discord"
        "slack"
        "spotify"
      ];
  };

  users.users.${cfg.username} = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "networkmanager" "docker" ];
    packages = globalUserPackages { pkgs = pkgs; };
  };

  environment = {
    shells = with pkgs; [ bash zsh ];
    systemPackages = systemPackages { pkgs = pkgs; };
  };

  virtualisation.docker.enable = true;
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  programs.virt-manager.enable = true;
  users.groups.libvirtd.members = [ "${cfg.username}" ];
  virtualisation.libvirtd.enable = true;

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "${cfg.username}" ];
  };
  programs.firefox.enable = true;
  programs.sway.enable = true;
  programs.zsh.enable = true;

  programs.gnupg.agent = { enable = true; };

  services.openssh.enable = true;
  services.gnome.gnome-keyring.enable = true;

}
