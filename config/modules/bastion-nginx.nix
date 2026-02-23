# Bastion nginx options module
{ lib, ... }:
let
  defaultCfg = import ../default.nix;
in
{
  options.bastionNginx = {
    domain = lib.mkOption {
      type = lib.types.str;
      default = defaultCfg.domain;
      description = "Primary domain for virtual hosts";
    };
    acmeEmail = lib.mkOption {
      type = lib.types.str;
      default = defaultCfg.email;
      description = "Email for ACME/Let's Encrypt certificates";
    };
  };
}
