{ ... }:
{
  # Krohnkite-specific KWin configuration
  # This file contains advanced tiling settings for the Krohnkite KWin script
  # Configuration based on i3 window manager behavior

  xdg.configFile."kwinrc".text = ''
    [Script-krohnkite]
    # Enable Krohnkite
    enableTiling=true

    # Layout settings (i3-like behavior)
    # 0 = Tile (default, like i3)
    # 1 = Monocle (fullscreen single window)
    # 2 = Spread (all windows visible)
    # 3 = Stair (cascading)
    layoutPerActivity=false
    layoutPerDesktop=false

    # Gap settings (matching i3-gaps style)
    # Set to 0 for no gaps (traditional i3), or 5-10 for i3-gaps style
    screenGapBottom=5
    screenGapLeft=5
    screenGapRight=5
    screenGapTop=5
    tileLayoutGap=5

    # Window behavior (i3-like)
    # Don't maximize single windows (keep gaps visible)
    monocleMaximize=false
    maximizeSoleTile=false

    # New window placement (i3-like: new windows go to the right)
    # false = new window becomes master (dwm-style)
    # true = new window goes to the right (i3-style)
    newWindowAsMaster=false

    # Border settings
    # Keep borders visible for better window identification
    noTileBorder=false

    # Limit tile width for ultrawide monitors (optional)
    # Set to 0 to disable, or a pixel value like 1920
    limitTileWidthRatio=0

    # Filter settings (windows to not tile)
    # Exclude system windows and popups
    ignoreClass=krunner,yakuake,spectacle,kded5,plasmashell,plasma,plasma-desktop,ksmserver,ksplashqml,ksplashsimple,ksplashx
    ignoreRole=quake,pop-up,popup,notification
    ignoreTitle=

    # Float specific window types
    floatUtility=true
    floatingClass=
    floatingTitle=

    # Directional key mode (use hjkl like vim/i3)
    directionalKeyMode=dwm

    # Adjust layout on window resize
    adjustLayout=true
    adjustLayoutLive=true

    # Keep floating windows above tiled windows
    keepFloatAbove=true

    # Prevent windows from being minimized when switching desktops
    preventMinimize=true

    # Prevent windows from being moved to other screens automatically
    preventProtrusion=true
  '';
}

