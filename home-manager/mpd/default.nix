{ pkgs, ... }:
{
  imports = [
    ./darwin.nix
    ./linux.nix
  ];

  # Cross-platform MPD clients. The mpd daemon itself is started by
  # darwin.nix (launchd) and by the NixOS system module on Linux.
  home.packages = with pkgs; [
    mpc
    ncmpcpp
  ];
}
