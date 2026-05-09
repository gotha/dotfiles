{ pkgs, ... }:
let
  cfg = import ../config/default.nix;
  fontsPkgs = import ../config/fonts.nix { inherit pkgs; };
in
{
  fonts.packages = fontsPkgs;

  time.timeZone = cfg.timeZone;
}
