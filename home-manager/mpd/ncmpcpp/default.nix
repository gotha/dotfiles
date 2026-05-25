{ pkgs, ... }:
{
  home.packages = with pkgs; [ ncmpcpp ];

  xdg.configFile."ncmpcpp/config".source = ./config;
}
