_:

{
  imports = [
    ./digitalocean.nix
    ./mail.nix
    ./nginx.nix
    ./roundcube.nix
    ./wireguard.nix
  ];

  # Limit journal size to save disk space
  services.journald.extraConfig = ''
    SystemMaxUse=100M
    SystemMaxFileSize=50M
    MaxRetentionSec=7day
  '';

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

  system.stateVersion = "25.05";
}
