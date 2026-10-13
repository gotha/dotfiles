{ lib, ... }:

{
  imports = [
    ./digitalocean.nix
    ./internal.nix
    ./mail.nix
    ./nginx.nix
    ./roundcube.nix
    ./wireguard.nix
  ];

  # Allow user to push closures via deploy-rs
  nix.settings.trusted-users = [
    "root"
    "gotha"
  ];

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 4096; # Size in MB
    }
  ];

  networking.useDHCP = true;

  # Pin to classic dbus until a planned reboot migrates to dbus-broker.
  # nixpkgs-unstable switched the default; switching live breaks activation.
  services.dbus.implementation = "dbus";

  # Bumping this moves the default PostgreSQL major version, which cannot read
  # roundcube's existing data directory.
  system.stateVersion = lib.mkForce "25.05";
}
