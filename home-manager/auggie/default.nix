# Auggie CLI
#
# Reuses the MCP configuration generated at ~/.config/mcp/mcp.json by aliasing
# `auggie` in a zsh snippet sourced from ~/.zshrc.
{ pkgs, ... }:
{
  imports = [ ../mcp ];

  home.packages = [ pkgs.gotha.auggie ];

  xdg.configFile."zsh/auggie.zsh".text = ''
    # Resume the most recent session for the current directory, or start a new one
    auggie() {
      local session_id
      session_id=$(command auggie session list --json 2>/dev/null | ${pkgs.jq}/bin/jq -r --arg cwd "$PWD" '[.[] | select(.workspace_roots[]? | contains($cwd))] | sort_by(.modified) | reverse | .[0].session_id // empty')
      if [[ -n "$session_id" ]]; then
        command auggie --mcp-config ~/.config/mcp/mcp.json --resume "$session_id"
      else
        command auggie --mcp-config ~/.config/mcp/mcp.json
      fi
    }
    alias auggie-new="auggie --mcp-config ~/.config/mcp/mcp.json"
  '';
}
