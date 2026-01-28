{ pkgs, ... }:
{

  home.packages = with pkgs; [
    bemoji
    rofi
  ];

  xdg.configFile."rofi/config.rasi".source = ./config.rasi;

}
