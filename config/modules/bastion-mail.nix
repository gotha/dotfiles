# Bastion mail options module
{ lib, ... }:
let
  defaultCfg = import ../default.nix;
in
{
  options.bastionMail = {
    domain = lib.mkOption {
      type = lib.types.str;
      default = defaultCfg.domain;
      description = "Mail domain";
    };
  };
}
