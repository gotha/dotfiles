{
  config,
  lib,
  pkgs,
  ...
}:
let
  musicDirectory = "${config.home.homeDirectory}/Music";
  dataDir = "${config.home.homeDirectory}/.mpd";
  mpdConf = pkgs.writeText "mpd.conf" ''
    music_directory    "${musicDirectory}"
    playlist_directory "${dataDir}/playlists"
    db_file            "${dataDir}/database"
    state_file         "${dataDir}/state"
    sticker_file       "${dataDir}/sticker.sql"
    log_file           "${dataDir}/log"
    pid_file           "${dataDir}/pid"

    bind_to_address    "127.0.0.1"
    port               "6600"

    audio_output {
      type    "osx"
      name    "CoreAudio"
    }
  '';
in
{
  config = lib.mkIf pkgs.stdenv.isDarwin {
    home.packages = with pkgs; [
      mpd
    ];

    # Create MPD directories
    home.activation.mpdDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p "${dataDir}/playlists"
    '';

    # LaunchAgent for MPD
    launchd.agents.mpd = {
      enable = true;
      config = {
        Label = "org.musicpd.mpd";
        ProgramArguments = [
          "${pkgs.mpd}/bin/mpd"
          "--no-daemon"
          "${mpdConf}"
        ];
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "${dataDir}/stdout.log";
        StandardErrorPath = "${dataDir}/stderr.log";
      };
    };
  };
}
