{ lib, pkgs, ... }:
let
  pluginsDir = ./plugins;
  pluginFiles = builtins.readDir pluginsDir;
  makePluginConfig = name: type:
    if type == "regular" then {
      "sketchybar/plugins/${name}" = {
        source = pluginsDir + "/${name}";
        executable = true;
      };
    } else
      { };
in {

  xdg.configFile = lib.mkMerge [
    (lib.mkMerge (lib.mapAttrsToList makePluginConfig pluginFiles))
    {
      "sketchybar/sketchybarrc" = {
        source = ./sketchybarrc.sh;
        executable = true;
      };
      "sketchybar/colors.sh" = {
        source = ./colors.sh;
        executable = true;
      };
    }
  ];

  launchd.agents.sketchybar = {
    enable = true;
    config = {
      ProgramArguments = [ "${pkgs.sketchybar}/bin/sketchybar" ];
      KeepAlive = false;
      RunAtLoad = true;
    };
  };

}
