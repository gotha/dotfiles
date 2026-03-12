{ pkgs, lib, ... }:
{
  config = lib.mkIf pkgs.stdenv.isLinux {
    # Start mpdris2 to expose MPD via MPRIS for waybar-mpris
    systemd.user.services.mpdris2 = {
      Unit = {
        Description = "MPRIS 2 support for MPD";
        After = [ "mpd.service" ];
      };
      Service = {
        ExecStart = "${pkgs.mpdris2}/bin/mpDris2";
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
