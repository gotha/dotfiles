# Lucie nextcloud options module
{ lib, ... }:
let
  defaultCfg = import ../default.nix;
in
{
  options.lucieNextcloud = {
    domain = lib.mkOption {
      type = lib.types.str;
      default = defaultCfg.domain;
      description = "Domain for Nextcloud";
    };
  };
}
