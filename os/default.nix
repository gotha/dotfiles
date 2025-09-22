{ pkgs, ... }:
let
  cfg = import ../config/default.nix;
  fontsPkgs = import ../config/fonts.nix { pkgs = pkgs; };
in {
  fonts.packages = fontsPkgs;

  time.timeZone = cfg.timeZone;
}
