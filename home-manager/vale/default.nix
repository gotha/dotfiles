{ pkgs, ... }:
{
  home.packages = [ pkgs.vale ];

  home.file.".vale.ini".source = ./vale.ini;
}
