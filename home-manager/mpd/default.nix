{ pkgs, ... }:
{
  imports = [
    ./darwin.nix
    ./linux.nix
    ./ncmpcpp
  ];

  # Cross-platform MPD clients.
  home.packages = with pkgs; [ mpc ];
}
