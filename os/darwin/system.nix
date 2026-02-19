{
  pkgs,
  systemPackages,
  username,
  ...
}:
{
  system.primaryUser = username;

  nix.settings = {
    trusted-users = [
      "root"
      "@admin"
      "${username}"
    ];
  };

  programs.zsh.enable = true;

  nixpkgs.config.allowUnfree = true;

  environment = {
    shells = with pkgs; [
      bash
      zsh
    ];
    systemPackages = systemPackages;
    systemPath = [ "/opt/homebrew/bin" ];
    pathsToLink = [ "/Applications" ];
    variables = {
      EDITOR = "vi";
    };
  };

  security.pam.services.sudo_local.touchIdAuth = true;

  system.keyboard.nonUS.remapTilde = true; # remap tilde to non-us
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
    #swapLeftCtrlAndFn = true;
  };

  system.defaults = {
    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      _FXShowPosixPathInTitle = true;
      ShowPathbar = true;
      ShowStatusBar = true;
      CreateDesktop = false;
    };
    dock = {
      autohide = true;
      autohide-delay = 5.0; # super slow to show dock; close to disabling it; default is 0.24
      minimize-to-application = true;
      orientation = "left";
      show-process-indicators = true;
      show-recents = false;
      wvous-tl-corner = 2; # top left hot corner - mission control
      wvous-br-corner = 1; # disable bottom right hot corner
      expose-group-apps = true; # fixes issue with small windows in Expose
      persistent-apps = [
        "/System/Applications/System Settings.app"
        "/Applications/Safari.app"
        "/Users/${username}/Applications/Home Manager Apps/Alacritty.app"
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
      _HIHideMenuBar = true;
    };
    trackpad = {
      Clicking = true; # tap to cick
      TrackpadRightClick = true;
      TrackpadThreeFingerDrag = true;
    };
  };
  # backwards compat; don't change
  system.stateVersion = 4;
  # configured group ID to match the current value because nix-darwin change
  # that would otherwise make me re-install
  ids.gids.nixbld = 350;
}
