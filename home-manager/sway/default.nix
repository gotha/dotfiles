{
  pkgs,
  config,
  lib,
  ...
}:
let
  wallpaperPkg = pkgs.callPackage ../../wallpaper { };
  cfg = config.programs.sway.custom;
in
{

  options.programs.sway.custom = {
    terminal = lib.mkOption {
      type = lib.types.enum [
        "kitty"
        "alacritty"
      ];
      default = "kitty";
      description = "Terminal emulator to use with sway";
    };

    # ../swayfx flips this to pkgs.swayfx. Everything else in this module -
    # keybinds, outputs, the xkb symbols - is identical either way.
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.sway;
      description = "Which sway build to install";
    };

    # Appended to ./config, so whatever lands here wins over it.
    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra sway config, appended verbatim";
    };
  };

  config = {
    # @todo -  add dependency on rofi and waybar modules
    # without adding them as packages here
    home = {
      packages = with pkgs; [
        brightnessctl
        grim # screenshots
        pulseaudio # pactl comes from pulseaudio
        cfg.package
        swaylock
        swayidle
        slurp # select region in a waylad compositor and print it to stdout
        wl-clipboard
        wob
      ];

      file = {
        ".xkb/symbols/keychron-k6".source = ./.xkb/symbols/keychron-k6;
        ".xkb/symbols/ducky-one-2sf".source = ./.xkb/symbols/ducky-one-2sf;
      };
    };

    xdg.configFile."sway/config".text =
      let
        baseConfig = builtins.readFile ./config;
        wallpaperImage = "${wallpaperPkg}/nix-wallpaper-nineish-solarized-dark.png";
        inherit (cfg) terminal;
      in
      builtins.replaceStrings [ "{{WALLPAPER}}" "{{TERMINAL}}" ] [ wallpaperImage terminal ] baseConfig
      + cfg.extraConfig;
  };
}
