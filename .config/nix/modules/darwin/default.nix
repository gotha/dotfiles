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
      httpie
      jq
      less
      lua
      ncdu
      neofetch
      neovim
      ( nerdfonts.override { fonts = [ "FiraCode" ]; })
      nodejs
      pandoc
      (php.buildEnv {
        extensions = ({ enabled, all }: enabled ++ (with all; [
          xdebug
        ]));
        extraConfig = ''
          xdebug.mode=debug
        '';
      })
      php.packages.composer
      php.packages.phpstan
      php.packages.php-cs-fixer
      phpactor
      pyright
      python3
      qemu
      ripgrep
      rustup
      shfmt
      stow
      stylua
      symfony-cli
      tcptraceroute
      tmux
      vale
      watch
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
    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      _FXShowPosixPathInTitle = true;
      ShowPathbar = true;
      ShowStatusBar = true;
    };
    dock = {
      autohide = true;
      minimize-to-application = true;
      orientation = "left";
      show-process-indicators = true;
      show-recents = false;
      wvous-tl-corner = 2; # launch MissionControl on top left hot corner
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
    taps = [
      "fujiapple852/trippy"
      "nikitabobko/aerospace"
    ];
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
