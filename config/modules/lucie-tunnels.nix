# Lucie tunnels options module
{ lib, ... }:
let
  defaultCfg = import ../default.nix;
in
{
  options.lucieTunnels = {
    domain = lib.mkOption {
      type = lib.types.str;
      default = defaultCfg.domain;
      description = "Domain for SSH tunnels";
    };
  };
}
