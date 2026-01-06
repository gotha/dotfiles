{ pkgs, config, ... }: {

  # Create admin password file
  # WARNING: This password is stored in the Nix store and is world-readable!
  # For production, use a secrets management solution like sops-nix
  environment.etc."nextcloud-admin-pass".text = "your-new-secure-password-here";

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud32;
    hostName = "nextcloud.hgeorgiev.com";

    # Use SQLite as backend database
    config = {
      adminpassFile = "/etc/nextcloud-admin-pass";
      dbtype = "sqlite";
    };

    # Trust the reverse proxy
    settings = {
      trusted_domains = [ "nextcloud.hgeorgiev.com" "10.100.0.100" "localhost" ];
      trusted_proxies = [ "10.100.0.1" ]; # bastion's WireGuard IP
      overwriteprotocol = "https";
      overwritehost = "nextcloud.hgeorgiev.com";
    };

    # Enable Redis for caching
    configureRedis = true;

    # Enable the Notes app
    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps) notes;
    };
    extraAppsEnable = true;

    # Optional: increase max upload file size
    maxUploadSize = "1G";
  };

  # Open firewall for Nextcloud (port 80)
  networking.firewall.allowedTCPPorts = [ 80 ];
}
