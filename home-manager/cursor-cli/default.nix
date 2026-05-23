# Cursor CLI (`cursor-agent`)
#
# Reads its MCP server configuration from ~/.cursor/mcp.json.
{ pkgs, config, ... }:
{
  imports = [ ../mcp ];

  home.packages = [ pkgs.cursor-cli ];

  home.file.".cursor/mcp.json".text = config.programs.mcp.configJSON;
}
