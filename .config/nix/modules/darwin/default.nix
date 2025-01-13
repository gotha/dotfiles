{ pkgs, ... }:
let
  cfg = import ../global/conf.nix;
  userPackages = import ../global/packages-user.nix;
  systemPackages = import ../global/packages.nix;
  fonts = import ../global/fonts.nix;
in {
  programs.zsh.enable = true;
  users.users."${cfg.username}".packages = userPackages { pkgs = pkgs; };
  environment = {
    shells = with pkgs; [ bash zsh ];
    systemPackages = systemPackages { pkgs = pkgs; };
    systemPath = [ "/opt/homebrew/bin" ];
    pathsToLink = [ "/Applications" ];
  };
  fonts.packages = fonts { pkgs = pkgs; };
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
  time.timeZone = cfg.timeZone;
  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToEscape = true;
  system.keyboard.nonUS.remapTilde = true; # remap tilde to non-us
  #system.keyboard.swapLeftCtrlAndFn = true;
  security.pam.enableSudoTouchIdAuth = true;
  system.defaults = {
    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      _FXShowPosixPathInTitle = true;
      ShowPathbar = true;
      ShowStatusBar = true;
    };
    dock = {
      autohide = true;
      autohide-delay =
        5.0; # super slow to show dock; close to disabling it; default is 0.24
      minimize-to-application = true;
      orientation = "left";
      show-process-indicators = true;
      show-recents = false;
      wvous-tl-corner = 1; # disable top left hot corner
      wvous-br-corner = 1; # disable bottom right hot corner
      persistent-apps = [
        "/System/Applications/System Settings.app"
        "/Applications/Safari.app"
        "/Applications/Alacritty.app"
        "/Applications/Chromium.app"
        "/Applications/Firefox.app"
        "/Applications/Slack.app"
        "/Applications/Spotify.app"
        "/Applications/1Password.app"
      ];
    };
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      InitialKeyRepeat = 14;
      KeyRepeat = 1;
    };
    trackpad = {
      Clicking = true; # tap to cick
      TrackpadRightClick = true;
      TrackpadThreeFingerDrag = true;
    };
  };
  # backwards compat; don't change
  system.stateVersion = 4;
  services.nix-daemon.enable = true;
  homebrew = {
    enable = true;
    caskArgs.no_quarantine = true;
    global.brewfile = true;
    masApps = { };
    casks = [
      "1password"
      "aerospace"
      "alacritty"
      "audacity"
      "chromium"
      "dbeaver-community"
      "discord"
      "firefox"
      "gimp"
      "inkscape"
      "karabiner-elements"
      "keka"
      "keycastr"
      "rar"
      "raycast"
      "slack"
      "spotify"
      "transmission"
      "utm"
      "viber"
      "vlc"
    ];
    taps = [ "fujiapple852/trippy" "nikitabobko/aerospace" ];
    brews =
      [ "autopep8" "cookiecutter" "cfn-lint" "go" "gofumpt" "gopls" "trippy" ];
  };
}
