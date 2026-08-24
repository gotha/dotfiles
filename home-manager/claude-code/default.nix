# Claude Code CLI
#
# Claude Code reads MCP servers from ~/.mcp.json or via the --mcp-config flag.
# We reuse the MCP configuration generated at ~/.config/mcp/mcp.json by
# aliasing `claude` in a zsh snippet sourced from ~/.zshrc.
{
  pkgs,
  lib,
  config,
  ...
}:
{
  imports = [ ../mcp ];

  home = {
    packages = [ pkgs.claude-code ];

    file = {
      # Load personal skills from the shared ~/.agents/skills location (managed
      # outside Nix, e.g. by the skill installer) by pointing ~/.claude/skills
      # at it. Out-of-store symlink so the target stays mutable.
      ".claude/skills".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.agents/skills";

      ".claude/settings.json".text = lib.generators.toJSON { } {
        theme = "dark";
        model = "claude-opus-5";
        skipDangerousModePermissionPrompt = true;
        includeCoAuthoredBy = false;
        # Web / Remote Control sessions otherwise append a
        # "Claude-Session: https://claude.ai/code/session_..." trailer to commits
        # and a matching link to PR bodies. includeCoAuthoredBy does not cover it.
        attribution.sessionUrl = false;
        effortLevel = "xhigh";

        extraKnownMarketplaces = {
          ponytail = {
            source = {
              source = "github";
              repo = "DietrichGebert/ponytail";
            };
          };
        };
        enabledPlugins = {
          "ponytail@ponytail" = true;
        };

        env = {
          CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN = "1";
          CLAUDE_CODE_DISABLE_FEEDBACK_SURVEY = "1";
          # effortLevel above is ignored while Opus 4.8's "launch effort pin"
          # is active (it forces the per-model default of "high"). The env var
          # takes top precedence and overrides the pin.
          CLAUDE_CODE_EFFORT_LEVEL = "xhigh";
        };
      };

      # attribution.sessionUrl above stops Claude Code appending the trailer
      # itself, but history written before that setting existed still carries it
      # - dissona, zensourcer and handshake have dozens of such commits. Claude
      # reads git log to match a repo's commit style and copies the trailer by
      # hand, so the setting alone does not end it. Say so explicitly.
      ".claude/CLAUDE.md".text = ''
        ## Git commits

        Never put a `Claude-Session:` trailer, a `Co-Authored-By: Claude` line, or
        any other Claude or session attribution in a commit message or PR body -
        not even when existing commits in the repository have one. That older
        history was produced by a Claude Code setting that is now disabled; it is
        not a convention to match.
      '';
    };
  };

  xdg.configFile."zsh/claude.zsh".text = ''
    alias claude="claude --mcp-config ~/.config/mcp/mcp.json --dangerously-skip-permissions"
  '';
}
