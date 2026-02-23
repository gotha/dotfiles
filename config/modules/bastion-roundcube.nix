# Bastion roundcube options module
{ lib, ... }:
let
  defaultCfg = import ../default.nix;
in
{
  options.bastionRoundcube = {
    domain = lib.mkOption {
      type = lib.types.str;
      default = defaultCfg.domain;
      description = "Domain for Roundcube webmail";
    };
  };
}
