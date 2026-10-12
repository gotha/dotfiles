_: {
  environment.systemPath = [ "/opt/homebrew/bin" ];

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
    };
    global.brewfile = true;
    masApps = { };
    casks = [
      "1password"
      "alacritty"
      "audacity"
      "chromium"
      "claude"
      "dbeaver-community"
      "discord"
      "firefox"
      "google-chrome"
      "gimp"
      "inkscape"
      "karabiner-elements"
      "keka"
      "keycastr"
      "kitty"
      "nextcloud"
      "openwhispr"
      "rar"
      "raycast"
      "slack"
      "spotify"
      "transmission"
      "utm"
      "viber"
      "vlc"
      "zoom"
    ];
    taps = [
      "fujiapple852/trippy"
      "FelixKratz/formulae"
      "jundot/omlx"
    ];
    brews = [
      "go"
      "gofumpt"
      "gopls"
      "git-secrets"
      "helm"
      "jundot/omlx/omlx"
      "nowplaying-cli"
      "trippy"
      "watchman"
    ];
  };
}
