{ pkgs, osConfig, ... }:
{
  home.packages = with pkgs; [ ncmpcpp ];

  # Keep ncmpcpp's mpd_music_dir in sync with the system mpd music_directory
  # so tag editing / local file features point at the right path per host.
  xdg.configFile."ncmpcpp/config".text = ''
    ${builtins.readFile ./config}
    mpd_music_dir = "${osConfig.services.mpd.settings.music_directory}"
  '';
}
