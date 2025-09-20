{ pkgs, ... }: {

  home.packages = with pkgs; [ aerospace ];

  # Add launchd service for AeroSpace (macOS specific)
  # This is an alternative to the start-at-login setting in the config
  launchd.agents.aerospace = {
    enable = true;
    config = {
      ProgramArguments = [ "${pkgs.aerospace}/bin/aerospace" ];
      KeepAlive = true;
      RunAtLoad = true;
    };
  };

  xdg.configFile."aerospace/aerospace.toml".source = ./aerospace.toml;

}
