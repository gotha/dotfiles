# Claude Code CLI
#
# Claude Code reads MCP servers from ~/.mcp.json or via the --mcp-config flag.
# We reuse the MCP configuration generated for Cursor at ~/.config/mcp/mcp.json
# by aliasing `claude` in zsh/.zshrc to pass --mcp-config, matching the pattern
# used for `auggie`.
{ pkgs, ... }:
{
  home.packages = [ pkgs.claude-code ];
}
