{ pkgs, ... }: {

  home.packages = with pkgs; [ bemoji rofi-wayland ];

  xdg.configFile."rofi/config.rasi".source = ./config.rasi;

}
