{ ... }:
{
  environment.systemPath = [ "/opt/homebrew/bin" ];

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
    };
    caskArgs.no_quarantine = true;
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
      "gimp"
      "inkscape"
      "intellij-idea"
      "karabiner-elements"
      "keka"
      "keycastr"
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
    ];
    taps = [
      "fujiapple852/trippy"
      "FelixKratz/formulae"
    ];
    brews = [
      "cookiecutter"
      "cfn-lint"
      "go"
      "gofumpt"
      "gopls"
      "helm"
      "trippy"
    ];
  };
}
