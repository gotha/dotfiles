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
    model = "claude-opus-4-8[1m]";
    skipDangerousModePermissionPrompt = true;
    includeCoAuthoredBy = false;
    effortLevel = "xhigh";
    env = {
      CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN = "1";
      CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY = "1";
      # effortLevel above is ignored while Opus 4.8's "launch effort pin"
      # is active (it forces the per-model default of "high"). The env var
      # takes top precedence and overrides the pin.
      CLAUDE_CODE_EFFORT_LEVEL = "xhigh";
    };
  };

  xdg.configFile."zsh/claude.zsh".text = ''
    alias claude="claude --mcp-config ~/.config/mcp/mcp.json --dangerously-skip-permissions"
  '';
}
