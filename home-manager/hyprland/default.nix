{
  pkgs,
  config,
  lib,
  ...
}:
{

  options.programs.hyprland.custom = {
    terminal = lib.mkOption {
      type = lib.types.enum [
        "kitty"
        "alacritty"
      ];
      default = "kitty";
      description = "Terminal emulator to use with hyprland";
    };

    hy3Package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.hyprlandPlugins.hy3;
      defaultText = lib.literalExpression "pkgs.hyprlandPlugins.hy3";
      description = ''
        hy3 build to load. Must be the one compiled against the hyprland the
        system runs: the plugin is dlopened into the compositor, so a build
        made against another version is refused and every hl.plugin.hy3 call
        in hyprland.lua then fails at config load.
      '';
    };
  };

  config = {
    home = {
      packages = with pkgs; [
        brightnessctl
        cliphist
        grim # screenshots
        hyprlauncher # replaces rofi; see hyprland.lua
        hyprpicker
        hyprpolkitagent
        hyprshot
        hyprsunset
        pulseaudio # pactl comes from pulseaudio
        rose-pine-hyprcursor
        slurp # select region in a wayland compositor and print it to stdout
        swayosd # volume/brightness OSD, works on any wlroots compositor
        wl-clip-persist # clipboard survives closing the app that owned it
        wl-clipboard
        wlogout
      ];

      # Shared with ../sway: libxkbcommon finds ~/.xkb the same way under
      # either compositor.
      file = {
        ".xkb/symbols/keychron-k6".source = ../sway/.xkb/symbols/keychron-k6;
        ".xkb/symbols/ducky-one-2sf".source = ../sway/.xkb/symbols/ducky-one-2sf;
      };
    };

    # hyprland 0.57 reads hypr/hyprland.lua and nothing else.
    xdg.configFile."hypr/hyprland.lua".text =
      let
        baseConfig = builtins.readFile ./hyprland.lua;
        terminal = config.programs.hyprland.custom.terminal;
        # libexec, so it is not on PATH.
        polkitAgent = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
        hy3 = "${config.programs.hyprland.custom.hy3Package}/lib/libhy3.so";
      in
      builtins.replaceStrings
        [ "{{TERMINAL}}" "{{POLKIT_AGENT}}" "{{HY3}}" ]
        [
          terminal
          polkitAgent
          hy3
        ]
        baseConfig;
  };
}
