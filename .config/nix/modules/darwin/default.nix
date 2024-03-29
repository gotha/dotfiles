{ pkgs, ... }: {
  # here go the darwin preferences and config items
  programs.zsh.enable = true;
  environment = {
    shells = with pkgs; [
      bash
      zsh
    ];
    loginShell = pkgs.zsh;
    systemPackages = with pkgs; [
      bison
      cloc
      coreutils
      curl
      git
      gnumake
      htop
      jq
      less
      stow
      tmux
      wget
    ];
    systemPath = [ "/opt/homebrew/bin" ];
    pathsToLink = [ "/Applications" ];
  };
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
  time.timeZone = "Europe/Sofia";
  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToEscape = true;
  system.keyboard.nonUS.remapTilde = true; # remap tilde to non-us
  services.nix-daemon.enable = true;
  system.defaults = {
    finder.AppleShowAllExtensions = true;
    finder.AppleShowAllFiles = true;
    finder._FXShowPosixPathInTitle = true;
    finder.ShowPathbar = true;
    finder.ShowStatusBar = true;
    dock.autohide = true;
    dock.minimize-to-application = true;
    dock.orientation = "left";
    dock.show-process-indicators = true;
    dock.show-recents = false;
    dock.wvous-tl-corner = 2; # launch MissionControl on top left hot corner
    NSGlobalDomain.AppleShowAllExtensions = true;
    NSGlobalDomain.InitialKeyRepeat = 14;
    NSGlobalDomain.KeyRepeat = 1;
    trackpad.Clicking = true; # tap to cick
    trackpad.TrackpadRightClick = true;
    trackpad.TrackpadThreeFingerDrag = true;
  };
  # backwards compat; don't change
  system.stateVersion = 4;
  homebrew = {
    enable = true;
    caskArgs.no_quarantine = true;
    global.brewfile = true;
    masApps = { };
    casks = [ 
      "1password"
      "alacritty"
      "dbeaver-community"
      "discord"
      "firefox"
      "gimp"
      "hammerspoon"
      "inkscape"
      "karabiner-elements"
      "keka"
      "keycastr"
      "rar"
      "raycast"
      #"slack"
      "spotify"
      "vlc" 
      "utm"
    ];
    taps = [ "fujiapple852/trippy" ];
    brews = [ 
      "autopep8"
      "cookiecutter"
      "cfn-lint"
      "go"
      "gofumpt"
      "gopls"
      "trippy" 
    ];
  };
}
