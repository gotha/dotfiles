{ pkgs, ... }:
let wallpaperPkg = pkgs.callPackage ../../wallpaper { };
in {
  # Import additional KDE configurations
  imports = [ ./autostart.nix ./kwinrc-krohnkite.nix ./kwinrulesrc.nix ];

  # KDE Plasma packages
  home.packages = with pkgs; [
    # Core KDE packages
    kdePackages.plasma-desktop
    kdePackages.plasma-workspace
    kdePackages.kwin
    kdePackages.systemsettings
    kdePackages.dolphin
    kdePackages.konsole
    kdePackages.spectacle # screenshots
    kdePackages.krunner # application launcher

    # Utilities (matching Sway setup)
    brightnessctl
    pulseaudio
    playerctl

    # rofi instead of KRunner
    rofi
  ];

  # KDE configuration files
  xdg.configFile = {
    # KWin configuration for tiling behavior with Krohnkite
    "kwinrc" = {
      text = ''
        [Plugins]
        # Enable Krohnkite tiling script (install separately)
        krohnkiteEnabled=true

        [Windows]
        BorderlessMaximizedWindows=false
        FocusPolicy=FocusFollowsMouse
        FocusStealingPreventionLevel=0
        # Disable maximize to prevent borders from disappearing
        ElectricBorderMaximize=false
        ElectricBorderTiling=false

        [org.kde.kdecoration2]
        BorderSize=Normal
        ButtonsOnLeft=
        ButtonsOnRight=

        [Desktops]
        Number=10
        Rows=1
      '';
    };

    # Plasma desktop configuration
    "plasma-org.kde.plasma.desktop-appletsrc" = {
      text = let
        wallpaperImage =
          "${wallpaperPkg}/nix-wallpaper-nineish-solarized-dark.png";
      in ''
        [Containments][1]
        wallpaperplugin=org.kde.image

        [Containments][1][Wallpaper][org.kde.image][General]
        Image=file://${wallpaperImage}

        [Containments][2]
        activityId=
        formfactor=2
        immutability=1
        lastScreen=0
        location=3
        plugin=org.kde.panel
        wallpaperplugin=org.kde.image

        [Containments][2][Applets][3]
        immutability=1
        plugin=org.kde.plasma.pager

        [Containments][2][Applets][3][Configuration][General]
        displayedText=Number
        showWindowIcons=false

        [Containments][2][General]
        AppletOrder=3

        [ScreenMapping]
        itemsOnDisabledScreens=
        screenMapping=
      '';
    };

    # Input device configuration (keyboard)
    "kcminputrc" = {
      text = ''
        [Keyboard]
        RepeatDelay=250
        RepeatRate=45

        [Layouts]
        LayoutList=us,bg
        Options=grp:win_space_toggle,caps:escape
      '';
    };

    # Display scaling configuration
    "kdeglobals" = {
      text = ''
        [KScreen]
        ScaleFactor=1
        ScreenScaleFactors=1

        [General]
        XftAntialias=true
        XftHintStyle=hintslight
        XftSubPixel=rgb
      '';
    };

    # Font DPI configuration (100% scaling = 96 DPI)
    "kcmfonts" = {
      text = ''
        [General]
        forceFontDPI=96
      '';
    };

    # Global keyboard shortcuts for Krohnkite tiling (i3-like)
    "kglobalshortcutsrc" = {
      text = ''
        [kwin]
        # Window cycling (Alt+Tab style but with Meta+H/L)
        Walk Through Windows (Reverse)=Meta+H,none,Walk Through Windows (Reverse)
        Walk Through Windows=Meta+L,none,Walk Through Windows

        # Krohnkite: Window focus (vim-style jk for up/down)
        # Note: Meta+H and Meta+L are used for window cycling instead of directional focus
        Krohnkite: Focus Down=Meta+J,none,Krohnkite: Focus Down
        Krohnkite: Focus Up=Meta+K,none,Krohnkite: Focus Up
        Krohnkite: Focus Left=none,none,Krohnkite: Focus Left
        Krohnkite: Focus Right=none,none,Krohnkite: Focus Right

        # Krohnkite: Window movement (matching i3)
        Krohnkite: Move Down=Meta+Shift+J,none,Krohnkite: Move Down
        Krohnkite: Move Up=Meta+Shift+K,none,Krohnkite: Move Up
        Krohnkite: Move Left=Meta+Shift+H,none,Krohnkite: Move Left
        Krohnkite: Move Right=Meta+Shift+L,none,Krohnkite: Move Right

        # Krohnkite: Master area control (i3-like)
        Krohnkite: Increase=Meta+I,none,Krohnkite: Increase Master Area Size
        Krohnkite: Decrease=Meta+U,none,Krohnkite: Decrease Master Area Size
        Krohnkite: Set master=Meta+Shift+Return,none,Krohnkite: Set as Master

        # Krohnkite: Layout control (i3-like)
        Krohnkite: Toggle Floating=Meta+Shift+Space,none,Krohnkite: Toggle Floating
        Krohnkite: Cycle Layout=Meta+Backslash,none,Krohnkite: Cycle Layout
        Krohnkite: Tile Layout=Meta+T,none,Krohnkite: Tile Layout
        Krohnkite: Monocle Layout=Meta+M,none,Krohnkite: Monocle Layout
        Krohnkite: Spread Layout=Meta+S,none,Krohnkite: Spread Layout
        Krohnkite: Stair Layout=Meta+Shift+S,none,Krohnkite: Stair Layout

        # Krohnkite: Resize mode (matching i3)
        # Note: Krohnkite doesn't have a resize mode, but we can use Meta+R for manual resize
        Window Resize=none,none,Resize Window

        # Window management (matching i3)
        Window Close=Meta+Shift+Q,Alt+F4,Close Window
        Window Fullscreen=Meta+F,none,Make Window Fullscreen
        Window Maximize=none,none,Maximize Window
        Window Minimize=none,none,Minimize Window

        # Virtual Desktops (workspaces - matching i3)
        Switch to Desktop 1=Meta+1,none,Switch to Desktop 1
        Switch to Desktop 2=Meta+2,none,Switch to Desktop 2
        Switch to Desktop 3=Meta+3,none,Switch to Desktop 3
        Switch to Desktop 4=Meta+4,none,Switch to Desktop 4
        Switch to Desktop 5=Meta+5,none,Switch to Desktop 5
        Switch to Desktop 6=Meta+6,none,Switch to Desktop 6
        Switch to Desktop 7=Meta+7,none,Switch to Desktop 7
        Switch to Desktop 8=Meta+8,none,Switch to Desktop 8
        Switch to Desktop 9=Meta+9,none,Switch to Desktop 9
        Switch to Desktop 10=Meta+0,none,Switch to Desktop 10

        # Move window to desktop (matching i3)
        Window to Desktop 1=Meta+Shift+1,none,Window to Desktop 1
        Window to Desktop 2=Meta+Shift+2,none,Window to Desktop 2
        Window to Desktop 3=Meta+Shift+3,none,Window to Desktop 3
        Window to Desktop 4=Meta+Shift+4,none,Window to Desktop 4
        Window to Desktop 5=Meta+Shift+5,none,Window to Desktop 5
        Window to Desktop 6=Meta+Shift+6,none,Window to Desktop 6
        Window to Desktop 7=Meta+Shift+7,none,Window to Desktop 7
        Window to Desktop 8=Meta+Shift+8,none,Window to Desktop 8
        Window to Desktop 9=Meta+Shift+9,none,Window to Desktop 9
        Window to Desktop 10=Meta+Shift+0,none,Window to Desktop 10

        # Screenshot (matching Sway config)
        Screenshot=Meta+P,Print,Take Screenshot

        # Reload KWin (similar to i3 reload)
        Krohnkite: Reload Script=Meta+Shift+C,none,Krohnkite: Reload Script

        [org.kde.krunner.desktop]
        # Application launcher (matching i3/Sway Meta+D)
        #_launch=Meta+D,Alt+Space,KRunner
        _launch=Meta+D,none,rofi

        [org.kde.konsole.desktop]
        # Terminal (matching i3/Sway Meta+Return)
        _launch=Meta+Return,none,alacritty

        [plasmashell]
        # Disable task manager shortcuts to avoid conflicts with workspace switching
        activate task manager entry 1=none,none,Activate Task Manager Entry 1
        activate task manager entry 2=none,none,Activate Task Manager Entry 2
        activate task manager entry 3=none,none,Activate Task Manager Entry 3
        activate task manager entry 4=none,none,Activate Task Manager Entry 4
        activate task manager entry 5=none,none,Activate Task Manager Entry 5
        activate task manager entry 6=none,none,Activate Task Manager Entry 6
        activate task manager entry 7=none,none,Activate Task Manager Entry 7
        activate task manager entry 8=none,none,Activate Task Manager Entry 8
        activate task manager entry 9=none,none,Activate Task Manager Entry 9
      '';
    };
  };
}
