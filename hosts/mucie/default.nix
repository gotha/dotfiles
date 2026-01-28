{ pkgs, username, ... }:
let
  wireguard = import ../../config/wireguard.nix;
in
{
  # macOS host configuration for mucie
  # This is a minimal host configuration for Darwin systems
  # Most configuration is handled by the platypus distro

  _module.args = {
    wireguard = wireguard;
  };

  imports = [
    ./wireguard.nix
  ];
}
