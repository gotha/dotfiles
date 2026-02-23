# Linux user options module
{ lib, ... }:
let
  defaultCfg = import ../default.nix;
in
{
  options.linuxUser = {
    sshPublicKey = lib.mkOption {
      type = lib.types.str;
      default = defaultCfg.sshPublicKey;
      description = "SSH public key for authorized_keys";
    };
  };
}
