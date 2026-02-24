# Headless Nextcloud client sync service (home-manager module)
{
  pkgs,
  config,
  ...
}:
let
  defaultCfg = import ../../config/default.nix;
  syncDir = "${config.home.homeDirectory}/Nextcloud";
  nextcloudUrl = "https://nextcloud.${defaultCfg.domain}";
in
{
  # Install nextcloud-client package (includes nextcloudcmd)
  home.packages = [ pkgs.nextcloud-client ];

  # Create the sync directory
  home.activation.createNextcloudDir = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "${syncDir}"
  '';

  # User-level systemd service for periodic sync
  systemd.user.services.nextcloud-sync = {
    Unit = {
      Description = "Nextcloud sync service";
      After = [
        "network-online.target"
        "sops-nix.service"
      ];
    };

    Service = {
      Type = "oneshot";
      Environment = [
        "HOME=${config.home.homeDirectory}"
        "PATH=${pkgs.coreutils}/bin"
      ];
      ExecStart = toString (
        pkgs.writeShellScript "nextcloud-sync.sh" ''
          USERNAME=$(cat ${config.sops.secrets.nextcloud_username.path})
          PASSWORD=$(cat ${config.sops.secrets.nextcloud_password.path})
          ${pkgs.nextcloud-client}/bin/nextcloudcmd --non-interactive -u "$USERNAME" -p "$PASSWORD" ${syncDir} ${nextcloudUrl}
        ''
      );
      Restart = "on-failure";
      RestartSec = "60";
    };
  };

  # Timer to run sync periodically (every 5 minutes)
  systemd.user.timers.nextcloud-sync = {
    Unit = {
      Description = "Nextcloud sync timer";
    };

    Timer = {
      OnBootSec = "2min";
      OnUnitActiveSec = "5min";
      Unit = "nextcloud-sync.service";
    };

    Install = {
      WantedBy = [ "timers.target" ];
    };
  };
}
