{ config, lib, pkgs, ... }:
let
  cfg = import ../global/conf.nix;
  systemPackages = import ../global/packages.nix;
  userPackages = import ../global/packages-user.nix;
  nixosUserPackages = import ./packages-user.nix;
  fonts = import ../global/fonts.nix;
in {
  networking.networkmanager.enable = true;

  time.timeZone = cfg.timeZone;

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  environment.systemPackages = systemPackages { pkgs = pkgs; };

  nixpkgs.config = {
    allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [ "1password" "1password-cli" "spotify" ];
    permittedInsecurePackages = [ "olm-3.2.16" ];
  };

  users.users."${cfg.username}" = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [
      "wheel" # Enable ‘sudo’ for the user.
      "networkmanager"
      "docker"
    ];
    packages = userPackages { pkgs = pkgs; }
      ++ nixosUserPackages { pkgs = pkgs; };

  };
  fonts.packages = fonts { pkgs = pkgs; };

  virtualisation.docker.enable = true;
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "${cfg.username}" ];
  };
  programs.sway.enable = true;
  programs.zsh.enable = true;

  services.openssh.enable = true;
  services.gnome.gnome-keyring.enable = true;

  system.autoUpgrade = {
    enable = true;
    allowReboot = false;
    channel = cfg.channel;
  };

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.11"; # Did you read the comment?

}
