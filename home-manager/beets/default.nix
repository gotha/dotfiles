{
  config,
  lib,
  pkgs,
  ...
}:
let
  musicDirectory =
    if pkgs.stdenv.isDarwin then "${config.home.homeDirectory}/Music" else "/mnt/storage/Music";
in
{
  home.packages = with pkgs; [
    beets
    # Optional dependencies for plugins
    python3Packages.pylast # for lastgenre plugin
    python3Packages.requests # for fetchart, lyrics
    python3Packages.beautifulsoup4 # for lyrics
    python3Packages.pyacoustid # for chroma plugin
    chromaprint # for chroma plugin (fpcalc)
  ];

  programs.beets = {
    enable = true;
    settings = {
      directory = musicDirectory;
      library = "${config.home.homeDirectory}/.config/beets/library.db";

      # Import settings
      import = {
        move = false; # copy files instead of moving
        copy = true;
        write = true; # write tags to files
        log = "${config.home.homeDirectory}/.config/beets/import.log";
      };

      # Path formats for organizing music
      paths = {
        default = "$albumartist/$album%aunique{} ($year)/$track - $title";
        singleton = "Non-Album/$artist - $title";
        comp = "Compilations/$album%aunique{} ($year)/$track - $title";
      };

      # Plugins
      plugins = [
        "chroma" # acoustic fingerprinting via AcoustID
        "spotify" # fetch metadata from Spotify
        "fetchart" # fetch album art
        "embedart" # embed art into files
        "lastgenre" # fetch genres from Last.fm
        "scrub" # clean up tags
        "replaygain" # calculate replay gain
        "info" # show file info
        "duplicates" # find duplicates
        "missing" # find missing tracks
        "mbsync" # sync with MusicBrainz
        "edit" # edit tags in editor
      ];

      # Plugin settings
      fetchart = {
        auto = true;
        minwidth = 300;
        maxwidth = 1200;
        sources = [
          "filesystem"
          "coverart"
          "itunes"
          "amazon"
        ];
      };

      embedart = {
        auto = true;
        ifempty = false;
        maxwidth = 500;
        remove_art_file = false;
      };

      lastgenre = {
        auto = true;
        count = 3;
        fallback = "Unknown";
        source = "album";
      };

      replaygain = {
        backend = "ffmpeg";
        auto = true;
      };

      chroma = {
        auto = true; # automatically fingerprint during import
      };

      spotify = {
        # Higher penalty = prefer MusicBrainz over Spotify
        data_source_mismatch_penalty = 0.3;
      };

      # UI settings
      ui = {
        color = true;
      };

      # Match settings
      match = {
        strong_rec_thresh = 0.1;
        medium_rec_thresh = 0.25;
        rec_gap_thresh = 0.25;
      };
    };
  };
}
