# Cursor CLI (`cursor-agent`)
#
# Reads its MCP server configuration from ~/.cursor/mcp.json.
{ pkgs, config, ... }:
{
  imports = [ ../mcp ];

  home.packages = [ pkgs.cursor-cli ];

  home.file.".cursor/mcp.json".text = config.programs.mcp.configJSON;

  # Match Claude's shell defaults, including approval to start MCP servers.
  xdg.configFile."zsh/cursor-cli.zsh".text = ''
    alias cursor-agent="cursor-agent --yolo --sandbox disabled --approve-mcps"
  '';
}
