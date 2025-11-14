{ pkgs, ... }: {

  home.packages = with pkgs; [
    kubectl-mcp-server
    mcp-atlassian
    mcp-server-git
  ];

  xdg.configFile."mcp/mcp.json".source = ./mcp.json;
}
