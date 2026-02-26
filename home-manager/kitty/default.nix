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
  };

  config = {

    home.packages = with pkgs; [ kitty ];

    xdg.configFile."kitty/kitty.conf".text =
      let
        baseConfig = builtins.readFile ./kitty.conf;
        fontSize = toString config.programs.kitty.custom.fontSize;
      in
      builtins.replaceStrings [ "{{FONT_SIZE}}" ] [ fontSize ] baseConfig;
  };
}
