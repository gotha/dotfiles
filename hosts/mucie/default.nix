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

  # Disable MCP servers that are either unreachable without VPN
  # (Grafana, Tempo), unused on this host (Gcloud), or
  # that we prefer not to load by default (Playwright).
  home-manager.users.${username}.programs.mcp = {
    enableGcloud = false;
    enableGrafana = false;
    enablePlaywright = false;
    enableTempo = false;
  };
}
