# Auggie CLI
#
# Reuses the MCP configuration generated at ~/.config/mcp/mcp.json by aliasing
# `auggie` in a zsh snippet sourced from ~/.zshrc.
{ pkgs, ... }:
{
  imports = [ ../mcp ];

  home.packages = [ pkgs.gotha.auggie ];

  xdg.configFile."zsh/auggie.zsh".text = ''
    alias auggie="auggie --mcp-config ~/.config/mcp/mcp.json --continue"
    alias auggie-new="auggie --mcp-config ~/.config/mcp/mcp.json"
  '';
}
