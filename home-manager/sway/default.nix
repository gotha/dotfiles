{ pkgs, ... }:
let
  wallpaperPkg = pkgs.callPackage ../../wallpaper { };
in
{

  # @todo -  add dependency on rofi and waybar modules
  # without adding them as packages here
  # also - browser (firefox) and terminal (alacritty)
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
    in
    builtins.replaceStrings [ "{{WALLPAPER}}" ] [ wallpaperImage ] baseConfig;

  home.file.".xkb/symbols/keychron-k6".source = ./.xkb/symbols/keychron-k6;
  home.file.".xkb/symbols/ducky-one-2sf".source = ./.xkb/symbols/ducky-one-2sf;

}
