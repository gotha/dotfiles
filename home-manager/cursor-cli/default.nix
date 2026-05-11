# Cursor CLI (`cursor-agent`)
#
# Reads its MCP server configuration from ~/.cursor/mcp.json, which the mcp
# home-manager module owns and writes.
{ pkgs, ... }:
{
  imports = [ ../mcp ];

  home.packages = [ pkgs.cursor-cli ];
}
