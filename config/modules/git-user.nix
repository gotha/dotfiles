# Git user options module (for home-manager)
{ lib, ... }:
let
  defaultCfg = import ../default.nix;
in
{
  options.programs.gitUser = {
    name = lib.mkOption {
      type = lib.types.str;
      default = defaultCfg.username;
      description = "Git user name";
    };
    email = lib.mkOption {
      type = lib.types.str;
      default = defaultCfg.email;
      description = "Git user email";
    };
    gpgSigningKey = lib.mkOption {
      type = lib.types.str;
      default = defaultCfg.gpgSigningKey;
      description = "GPG key for signing commits";
    };
  };
}
