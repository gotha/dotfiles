# 1Password, CLI and GUI.
#
# Stays a NixOS module rather than moving to ../../home-manager: both halves
# want a group and a setgid wrapper in /run/wrappers - onepassword-cli for the
# CLI, onepassword for the browser integration - and home-manager has no way to
# ask for either. The GUI additionally names who may answer its polkit prompts.
{ username, ... }:
{
  programs = {
    _1password.enable = true;
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = [ username ];
    };
  };
}
