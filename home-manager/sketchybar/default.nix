{
  config,
  lib,
  pkgs,
  ...
}:
let
  pluginsDir = ./plugins;
  pluginFiles = builtins.readDir pluginsDir;

  # Plugins that require path substitution (mpc path)
  # Maps plugin filename to substitution variables
  pluginsWithSubstitution = {
    "now_playing_helper.sh" = {
      mpc = pkgs.mpc;
    };
  };

  # Generate config for plugins with substitutions
  substitutedPluginConfigs = lib.mapAttrs' (
    name: vars:
    lib.nameValuePair "sketchybar/plugins/${name}" {
      source = pkgs.replaceVars (pluginsDir + "/${name}") vars;
      executable = true;
    }
  ) pluginsWithSubstitution;

  # Generate config for regular plugins (no substitution needed)
  # Excludes plugins that have substitutions
  regularPluginConfigs = builtins.listToAttrs (
    builtins.filter (x: x != null) (
      lib.mapAttrsToList (
        name: type:
        if type == "regular" && !builtins.hasAttr name pluginsWithSubstitution then
          {
            name = "sketchybar/plugins/${name}";
            value = {
              source = pluginsDir + "/${name}";
              executable = true;
            };
          }
        else
          null
      ) pluginFiles
    )
  );

  # Static config files
  staticConfigs = {
    "sketchybar/sketchybarrc" = {
      source = ./sketchybarrc.sh;
      executable = true;
    };
    "sketchybar/colors.sh" = {
      source = ./colors.sh;
      executable = true;
    };
  };
in
{
  xdg.configFile = lib.mkMerge [
    substitutedPluginConfigs
    regularPluginConfigs
    staticConfigs
  ];

  launchd.agents.sketchybar = {
    enable = true;
    config = {
      ProgramArguments = [ "${pkgs.sketchybar}/bin/sketchybar" ];
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/sketchybar.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/sketchybar.log";
      EnvironmentVariables = {
        PATH = "${pkgs.sketchybar}/bin:${pkgs.aerospace}/bin:/etc/profiles/per-user/${config.home.username}/bin:/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      };
    };
  };
}
