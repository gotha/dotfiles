{
  config,
  lib,
  pkgs,
  ...
}:
{

  options.programs.alacritty.custom = {
    fontSize = lib.mkOption {
      type = lib.types.number;
      default = 10.0;
      description = "Font size for Alacritty terminal";
    };
  };

  config = {

    home.packages = with pkgs; [ alacritty ];

    xdg.configFile."alacritty/alacritty.toml".text =
      let
        baseConfig = builtins.readFile ./alacritty.toml;
        fontSize = toString config.programs.alacritty.custom.fontSize;
      in
      builtins.replaceStrings [ "{{FONT_SIZE}}" ] [ fontSize ] baseConfig;
  };
}
