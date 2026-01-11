{ config, pkgs, username, ... }:

{
  # Install Nextcloud client
  environment.systemPackages = with pkgs; [
    nextcloud-client
  ];

  # Create sync directory
  systemd.tmpfiles.rules = [
    "d /home/${username}/Nextcloud 0755 ${username} users -"
  ];

  # Create systemd service for Nextcloud client sync
  systemd.services.nextcloud-client = {
    description = "Nextcloud Client Sync Service";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      User = username;
      Group = "users";
      ExecStart = "${pkgs.nextcloud-client}/bin/nextcloudcmd --non-interactive --path / /home/${username}/Nextcloud https://nextcloud.hgeorgiev.com";
      Restart = "on-failure";
      RestartSec = "60s";
      
      # Environment variables
      Environment = [
        "HOME=/home/${username}"
      ];
    };
  };

  # Create a timer to run sync periodically (every 15 minutes)
  systemd.timers.nextcloud-client = {
    description = "Nextcloud Client Sync Timer";
    wantedBy = [ "timers.target" ];
    
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "15min";
      Unit = "nextcloud-client.service";
    };
  };

  # Note: You need to manually configure credentials
  # Run as your user:
  # nextcloudcmd --user gotha --password YOUR_PASSWORD /home/gotha/Nextcloud https://nextcloud.hgeorgiev.com
  # This will create the config file at ~/.config/Nextcloud/nextcloudcmd.cfg
}

