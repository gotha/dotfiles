{ config, pkgs, ... }: {

  home.packages = with pkgs; [ aerospace ];

  launchd.agents.aerospace = {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.aerospace}/Applications/AeroSpace.app/Contents/MacOS/AeroSpace"
      ];
      KeepAlive = true;
      RunAtLoad = true;
      ProcessType = "Interactive";
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/aerospace.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/aerospace.log";
    };
  };

  xdg.configFile."aerospace/aerospace.toml".source = ./aerospace.toml;

}
