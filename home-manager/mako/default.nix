{ pkgs, ... }:
{

  home.packages = with pkgs; [ mako ];

  xdg.configFile."mako/config".source = ./config;
}
