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
      "dbeaver-community"
      "discord"
      "firefox"
      "google-chrome"
      "gimp"
      "inkscape"
      "intellij-idea"
      "karabiner-elements"
      "keka"
      "keycastr"
      "kitty"
      "nextcloud"
      "rar"
      "raycast"
      "redis-insight"
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
      "cookiecutter"
      "cfn-lint"
      "go"
      "gofumpt"
      "gopls"
      "helm"
      "jundot/omlx/omlx"
      "nowplaying-cli"
      "trippy"
    ];
  };
}
