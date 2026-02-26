{
  pkgs,
  config,
  lib,
  ...
}:
let
  wallpaperPkg = pkgs.callPackage ../../wallpaper { };
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
  };

  config = {
    # @todo -  add dependency on rofi and waybar modules
    # without adding them as packages here
    home.packages = with pkgs; [
      brightnessctl
      grim # screenshots
      pulseaudio # pactl comes from pulseaudio
      sway
      swaylock
      swayidle
      slurp # select region in a waylad compositor and print it to stdout
      wl-clipboard
      wob
    ];

    xdg.configFile."sway/config".text =
      let
        baseConfig = builtins.readFile ./config;
        wallpaperImage = "${wallpaperPkg}/nix-wallpaper-nineish-solarized-dark.png";
        terminal = config.programs.sway.custom.terminal;
      in
      builtins.replaceStrings [ "{{WALLPAPER}}" "{{TERMINAL}}" ] [ wallpaperImage terminal ] baseConfig;

    home.file.".xkb/symbols/keychron-k6".source = ./.xkb/symbols/keychron-k6;
    home.file.".xkb/symbols/ducky-one-2sf".source = ./.xkb/symbols/ducky-one-2sf;
  };
}
