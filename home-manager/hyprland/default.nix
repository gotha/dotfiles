# Hyprland for h4kbox, the sway module's counterpart.
#
# Structured the same way as ../sway: a plain config file with {{PLACEHOLDER}}
# substitution rather than home-manager's wayland.windowManager.hyprland, so the
# config stays readable as Hyprland config and can be diffed against
# ../sway/config.
#
# The Hyprland binary itself is not in home.packages - programs.hyprland.enable
# on the NixOS side owns that, because it also wires up the session, the portal
# and the polkit bits. This module is only the user-side configuration and the
# tools the config calls out to.
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

  options.programs.hyprland.custom = {
    terminal = lib.mkOption {
      type = lib.types.enum [
        "kitty"
        "alacritty"
      ];
      default = "kitty";
      description = "Terminal emulator to use with Hyprland";
    };
  };

  config = {
    home = {
      packages = with pkgs; [
        brightnessctl
        grim # screenshots
        hypridle # idle daemon, replaces swayidle
        hyprlock # screen locker, replaces swaylock
        hyprpaper # wallpaper daemon, replaces sway's `output * bg`
        hyprpicker # colour picker
        playerctl
        pulseaudio # pactl comes from pulseaudio
        slurp # select a region and print it to stdout
        wl-clipboard
      ];

      # Same custom xkb layouts the sway module installs. Referenced from
      # ../sway rather than copied so the two window managers cannot drift -
      # h4kbox disables the sway module, so nothing else puts these in place.
      file = {
        ".xkb/symbols/keychron-k6".source = ../sway/.xkb/symbols/keychron-k6;
        ".xkb/symbols/ducky-one-2sf".source = ../sway/.xkb/symbols/ducky-one-2sf;
      };
    };

    xdg.configFile = {
      "hypr/hyprland.conf".text =
        let
          terminal = config.programs.hyprland.custom.terminal;
        in
        builtins.replaceStrings [ "{{TERMINAL}}" ] [ terminal ] (builtins.readFile ./hyprland.conf);

      "hypr/hyprpaper.conf".text =
        let
          wallpaperImage = "${wallpaperPkg}/nix-wallpaper-nineish-solarized-dark.png";
        in
        builtins.replaceStrings [ "{{WALLPAPER}}" ] [ wallpaperImage ] (builtins.readFile ./hyprpaper.conf);

      "hypr/hypridle.conf".source = ./hypridle.conf;
    };
  };
}
