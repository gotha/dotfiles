{ config, pkgs, ... }:
let
  firefoxWorkspaces = pkgs.writeShellApplication {
    name = "aerospace-firefox-workspaces";
    runtimeInputs = with pkgs; [
      aerospace
      jq
      coreutils
    ];
    text = builtins.readFile ./firefox-workspaces.sh;
  };
in
{

  home.packages = [
    pkgs.aerospace
    firefoxWorkspaces
  ];

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
      EnvironmentVariables = {
        PATH = "${pkgs.sketchybar}/bin:${pkgs.aerospace}/bin:/etc/profiles/per-user/${config.home.username}/bin:/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      };
    };
  };

  # Wait for restored names and assign each Firefox window once per lifetime.
  launchd.agents.aerospace-firefox-workspaces = {
    enable = true;
    config = {
      ProgramArguments = [ "${firefoxWorkspaces}/bin/aerospace-firefox-workspaces" ];
      KeepAlive = true;
      RunAtLoad = true;
      ProcessType = "Background";
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/aerospace-firefox-workspaces.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/aerospace-firefox-workspaces.log";
    };
  };

  xdg.configFile."aerospace/aerospace.toml".source = ./aerospace.toml;

}
