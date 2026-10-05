# Live TV from iptv-org's public index: every Bulgarian channel it lists, plus a
# few global news ones. iptvsimple reads one playlist, so the filtering happens
# here rather than by pointing it at a URL.
{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  playlist = "/var/lib/iptv/channels.m3u";
  home = config.users.users.${username}.home;
  addonData = "${home}/.kodi/userdata/addon_data/pvr.iptvsimple";

  # tvg-ids exactly as the index spells them, quality suffix included.
  worldChannels = [
    "AlJazeera.qa@English"
    "BBCNews.uk@Europe"
    "DW.de@English"
    "EuronewsEnglish.fr@HD"
    "France24.fr@English"
    "SkyNews.ie@HD"
  ];

  filter = pkgs.writeText "iptv-filter.awk" ''
    BEGIN { split(keep, k, ","); for (i in k) want[k[i]] = 1; print "#EXTM3U" }

    /^#EXTINF/ {
      sub(/\r$/, "");
      buf = $0; id = "";
      if (match($0, /tvg-id="[^"]*"/)) id = substr($0, RSTART + 8, RLENGTH - 9);
      take = (id ~ /\.bg@/) || (id in want);
      next;
    }

    # EXTVLCOPT and KODIPROP lines carry the user agent some streams demand, so
    # they have to travel with their entry.
    /^#/ { if (take) { sub(/\r$/, ""); buf = buf "\n" $0 } next }

    NF { if (take) { sub(/\r$/, ""); print buf "\n" $0; n++ } take = 0 }

    END { printf "kept %d channels\n", n > "/dev/stderr" }
  '';

  fetch = pkgs.writeShellApplication {
    name = "iptv-playlist";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      gawk
    ];
    text = ''
      src=$(mktemp)
      trap 'rm -f "$src"' EXIT
      curl -fsS --max-time 180 -o "$src" https://iptv-org.github.io/iptv/index.m3u
      gawk -v keep=${lib.escapeShellArg (lib.concatStringsSep "," worldChannels)} \
        -f ${filter} "$src" > ${playlist}.new
      mv ${playlist}.new ${playlist}
    '';
  };

  settings = pkgs.writeText "iptvsimple-settings.xml" ''
    <settings version="2">
        <setting id="m3uPathType">0</setting>
        <setting id="m3uPath">${playlist}</setting>
        <setting id="m3uRefreshMode">1</setting>
        <setting id="m3uRefreshIntervalMins">60</setting>
        <setting id="startNum">1</setting>
        <setting id="numberByOrder">true</setting>
    </settings>
  '';
in
{
  systemd = {
    services.iptv-playlist = {
      description = "Refresh the IPTV channel list";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe fetch;
        StateDirectory = "iptv";
      };
    };

    timers.iptv-playlist = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        # OnBootSec is what gets a card its first playlist. Persistent only
        # replays an elapse it can prove it missed, and with no stamp file yet
        # there is nothing to miss - a fresh card would sit at 0% until
        # midnight, which is exactly what it did.
        OnBootSec = "1min";
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
    };

    # iptvsimple keeps its config in mutable addon_data, so stamp it from the
    # store on every boot: the playlist above wins over whatever the GUI saved.
    tmpfiles.rules = [
      "d ${home}/.kodi 0755 ${username} users -"
      "d ${home}/.kodi/userdata 0755 ${username} users -"
      "d ${home}/.kodi/userdata/addon_data 0755 ${username} users -"
      "d ${addonData} 0755 ${username} users -"
      "C+ ${addonData}/settings.xml 0644 ${username} users - ${settings}"
    ];
  };
}
