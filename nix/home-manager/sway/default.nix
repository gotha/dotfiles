{ pkgs, ... }:
let
  mod = "Mod4";
  term = "alacritty";
  menu = "rofi -show combi -show-icons";
  keyboard = {
    repeat_delay = "250";
    repeat_rate = "45";
  };
  wallpaperPkg = pkgs.callPackage ../../wallpaper { };

in {

  home.packages = with pkgs; [
    alacritty
    brightnessctl
    firefox
    grim # screenshots
    pulseaudio # pactl comes from pulseaudio
    rofi-wayland
    swaylock
    swayidle
    slurp # select region in a waylad compositor and print it to stdout
    wl-clipboard
    wob
  ];

  wayland.windowManager.sway = {
    enable = true;
    #extraOptions = [ "--unsupported-gpu" ];
    # swayfx just doesnt work with nvidia
    #package = pkgs.swayfx;

    config = {
      modifier = "${mod}";

      terminal = "alacritty";

      bars = [{
        command = "${pkgs.waybar}/bin/waybar";
        # position = "top";
      }];

      menu = "rofi -show combi -show-icons";

      output."*" = {
        background =
          "${wallpaperPkg}/nix-wallpaper-nineish-solarized-dark.png fill";
      };

      # Input configuration
      input = {
        "type:keyboard" = {
          xkb_layout = "us,bg";
          xkb_options = "grp:win_space_toggle,caps:escape";
          repeat_delay = keyboard.repeat_delay;
          repeat_rate = keyboard.repeat_rate;
        };

        "type:touchpad" = {
          tap = "enabled";
          natural_scroll = "enabled";
        };
      };

      startup = [
        { command = "${pkgs.alacritty}/bin/alacritty"; }
        { command = "${pkgs.firefox}/bin/firefox"; }
      ];

      assigns = {
        "1" = [{ app_id = "firefox"; }];
        "2" = [{ app_id = "Alacritty"; }];
      };

      # this is buggy and does not work - @todo - figure out how to fix it
      # Borders and gaps
      window = {
        border = 0;
        hideEdgeBorders = "none";
      };

      gaps = {
        inner = 5;
        outer = 5;
      };

      keybindings = {
        # Basics
        "${mod}+Return" = "exec ${term}";
        "${mod}+Shift+q" = "kill";
        "${mod}+d" = "exec ${menu}";
        "${mod}+Shift+c" = "reload";
        "${mod}+Shift+e" =
          "exec swaynag -t warning -m 'You pressed the exit shortcut. Do you really want to exit sway? This will end your Wayland session.' -B 'Yes, exit sway' 'swaymsg exit' ";

        # Move focus
        "${mod}+h" = "focus left";
        "${mod}+j" = "focus down";
        "${mod}+k" = "focus up";
        "${mod}+l" = "focus right";
        "${mod}+Left" = "focus left";
        "${mod}+Down" = "focus down";
        "${mod}+Up" = "focus up";
        "${mod}+Right" = "focus right";

        # Move windows
        "${mod}+Shift+h" = "move left";
        "${mod}+Shift+j" = "move down";
        "${mod}+Shift+k" = "move up";
        "${mod}+Shift+l" = "move right";
        "${mod}+Shift+Left" = "move left";
        "${mod}+Shift+Down" = "move down";
        "${mod}+Shift+Up" = "move up";
        "${mod}+Shift+Right" = "move right";

        # Layout
        "${mod}+b" = "splith";
        "${mod}+v" = "splitv";
        "${mod}+s" = "layout stacking";
        "${mod}+w" = "layout tabbed";
        "${mod}+e" = "layout toggle split";
        "${mod}+f" = "fullscreen";
        "${mod}+Shift+space" = "floating toggle";
        "${mod}+space" = "focus mode_toggle";
        "${mod}+a" = "focus parent";

        # Scratchpad
        "${mod}+Shift+minus" = "move scratchpad";
        "${mod}+minus" = "scratchpad show";
        # Resize mode

        "${mod}+r" = "mode resize";
        # Workspaces 1–10 (switch)
        "${mod}+1" = "workspace number 1";
        "${mod}+2" = "workspace number 2";
        "${mod}+3" = "workspace number 3";
        "${mod}+4" = "workspace number 4";
        "${mod}+5" = "workspace number 5";
        "${mod}+6" = "workspace number 6";
        "${mod}+7" = "workspace number 7";
        "${mod}+8" = "workspace number 8";
        "${mod}+9" = "workspace number 9";
        "${mod}+0" = "workspace number 10";

        # Move focused container to workspace 1–10
        "${mod}+Shift+1" = "move container to workspace number 1";
        "${mod}+Shift+2" = "move container to workspace number 2";
        "${mod}+Shift+3" = "move container to workspace number 3";
        "${mod}+Shift+4" = "move container to workspace number 4";
        "${mod}+Shift+5" = "move container to workspace number 5";
        "${mod}+Shift+6" = "move container to workspace number 6";
        "${mod}+Shift+7" = "move container to workspace number 7";
        "${mod}+Shift+8" = "move container to workspace number 8";
        "${mod}+Shift+9" = "move container to workspace number 9";
        "${mod}+Shift+0" = "move container to workspace number 10";
      };
    };

    # Additional Sway configuration for swayfx effects
    #extraConfig = ''
    #  # SwayFX specific configuration
    #  corner_radius 10

    #  shadows enable
    #  shadows_on_csd disable
    #  shadow_blur_radius 20
    #  shadow_color #0000007F
    #  shadow_inactive_color #0000004F
    #  shadow_offset 2 2

    #  # Layer effects for waybar
    #  layer_effects "waybar" {
    #    shadows enable;
    #    corner_radius 6;
    #  }

    #  # Environment variable for wob
    #  set $WOBSOCK $XDG_RUNTIME_DIR/wob.sock
    #'';
  };
}
