{
  pkgs,
  username,
  config,
  ...
}:
let
  cfg = config.lucieTunnels;
in
{
  imports = [
    ../../config/modules/lucie-tunnels.nix
  ];

  config = {
    systemd.services.hg-tunnel = {
      enable = true;
      description = "Setup a secure tunnel to ${cfg.domain}";
      after = [ "network.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        User = username;
        ExecStart = "${pkgs.openssh}/bin/ssh -NT -o ServerAliveInterval=60 -o ExitOnForwardFailure=yes -R 2224:localhost:22 ${username}@${cfg.domain}";

        RestartSec = 5;
        Restart = "always";

        Type = "simple";
      };

      environment = {
        HOME = "/home/${username}";
      };
    };

    systemd.services.jellyfin-tunnel = {
      enable = true;
      description = "SSH tunnel for Jellyfin to ${cfg.domain}";
      after = [ "network.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        User = "${username}";
        ExecStart = "${pkgs.openssh}/bin/ssh -NT -o ServerAliveInterval=60 -o ExitOnForwardFailure=yes -R 8096:localhost:8096 ${username}@${cfg.domain}";

        RestartSec = 5;
        Restart = "always";

        Type = "simple";
      };

      environment = {
        HOME = "/home/${username}";
      };
    };

    systemd.services.nix-serve-tunnel = {
      enable = true;
      description = "SSH tunnel for nix-server to ${cfg.domain}";
      after = [ "network.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        User = "${username}";
        ExecStart = "${pkgs.openssh}/bin/ssh -NT -o ServerAliveInterval=60 -o ExitOnForwardFailure=yes -R 5000:localhost:5000 ${username}@${cfg.domain}";

        RestartSec = 5;
        Restart = "always";

        Type = "simple";
      };

      environment = {
        HOME = "/home/${username}";
      };
    };
  };
}
