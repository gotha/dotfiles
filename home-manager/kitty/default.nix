{
  config,
  lib,
  pkgs,
  ...
}:
{

  options.programs.kitty.custom = {
    fontSize = lib.mkOption {
      type = lib.types.number;
      default = 10.0;
      description = "Font size for Kitty terminal";
    };
    fontFamily = lib.mkOption {
      type = lib.types.str;
      default = "FiraCode Nerd Font Propo";
      description = "Font family for Kitty terminal";
    };
  };

  config = {

    home.packages = with pkgs; [ kitty ];

    xdg.configFile."kitty/kitty.conf".text =
      let
        baseConfig = builtins.readFile ./kitty.conf;
        fontSize = toString config.programs.kitty.custom.fontSize;
        fontFamily = config.programs.kitty.custom.fontFamily;
      in
      builtins.replaceStrings [ "{{FONT_SIZE}}" "{{FONT_FAMILY}}" ] [ fontSize fontFamily ] baseConfig;
  };
}
