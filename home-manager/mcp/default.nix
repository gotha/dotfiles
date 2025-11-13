{ pkgs, ... }: {

  home.packages = with pkgs; [ mcp-atlassian mcp-server-git ];

  xdg.configFile."mcp/mcp.json".source = ./mcp.json;
}
