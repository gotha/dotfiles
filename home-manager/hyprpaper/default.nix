{ pkgs, ... }:
let
  wallpaperPkg = pkgs.callPackage ../../wallpaper { };
  image = "${wallpaperPkg}/nix-wallpaper-nineish-solarized-dark.png";
in
{

  home.packages = [ pkgs.hyprpaper ];

  # hyprland has no built-in wallpaper, unlike sway's `output * bg`.
  #
  # This is hyprpaper 0.8's config format, which is not the one every guide
  # still shows. The old `preload = <path>` + `wallpaper = <monitor>,<path>`
  # pair is gone: `wallpaper` is now a hyprlang special category keyed on
  # monitor, and there is no preload step at all.
  #
  # Getting this wrong fails quietly, which is the annoying part. hyprpaper
  # starts, parses without complaint, reports no error - and then logs
  # "Monitor <name> has no target: no wp will be created" and draws nothing,
  # leaving a background layer that never appears in `hyprctl layers`.
  #
  # An empty `monitor` means every output.
  xdg.configFile."hypr/hyprpaper.conf".text = ''
    splash = 0
    ipc = 1

    wallpaper {
        monitor =
        path = ${image}
        fit_mode = cover
    }
  '';
}
