{ lib, ... }:
{

  nixpkgs.config = {
    # @todo - fix this; it should not be allowUnfree = true
    allowUnfree = true;
    allowUnfreePredicate =
      pkg:
      builtins.elem (lib.getName pkg) [
        "1password"
        "1password-cli"
        "discord"
        "nvidia-X11"
        "slack"
        "spotify"
        "steam"
        "steam-original"
        "steam-unwrapped"
        "steam-run"
      ];
  };
}
