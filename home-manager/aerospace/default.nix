{ pkgs, ... }: {

  home.packages = with pkgs; [ aerospace ];

  launchd.agents.aerospace = {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.aerospace}/Applications/AeroSpace.app/Contents/MacOS/AeroSpace"
      ];
      KeepAlive = false;
      RunAtLoad = true;
    };
  };

  xdg.configFile."aerospace/aerospace.toml".source = ./aerospace.toml;

}
