# Claude Code CLI
#
# Claude Code reads MCP servers from ~/.mcp.json or via the --mcp-config flag.
# We reuse the MCP configuration generated at ~/.config/mcp/mcp.json by
# aliasing `claude` in a zsh snippet sourced from ~/.zshrc.
{ pkgs, ... }:
{
  imports = [ ../mcp ];

  home.packages = [ pkgs.claude-code ];

  xdg.configFile."zsh/claude.zsh".text = ''
    alias claude="claude --mcp-config ~/.config/mcp/mcp.json"
  '';
}
