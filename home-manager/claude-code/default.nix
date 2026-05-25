# Claude Code CLI
#
# Claude Code reads MCP servers from ~/.mcp.json or via the --mcp-config flag.
# We reuse the MCP configuration generated at ~/.config/mcp/mcp.json by
# aliasing `claude` in a zsh snippet sourced from ~/.zshrc.
{ pkgs, lib, ... }:
{
  imports = [ ../mcp ];

  home.packages = [ pkgs.claude-code ];

  home.file.".claude/settings.json".text = lib.generators.toJSON { } {
    theme = "dark";
    skipDangerousModePermissionPrompt = true;
    includeCoAuthoredBy = false;
    env = {
      CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN = "1";
    };
  };

  xdg.configFile."zsh/claude.zsh".text = ''
    alias claude="claude --mcp-config ~/.config/mcp/mcp.json --dangerously-skip-permissions"
  '';
}
