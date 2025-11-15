{ pkgs, ... }: {

  home.packages = with pkgs; [
    context7-mcp
    kubectl-mcp-server
    mcp-atlassian
    mcp-server-git
  ];

  xdg.configFile."mcp/mcp.json".text = builtins.toJSON {
    "$schema" = "https://modelcontextprotocol.io/schema/mcp.json";
    mcpServers = {
      atlassian = {
        command = "${pkgs.mcp-atlassian}/bin/mcp-atlassian";
        args = [ "--env-file" "~/.env" ];
        description =
          "Atlassian MCP server for managing JIRA projects and issues, and Confluence content";
      };
      "context-7" = {
        command = "${pkgs.context7-mcp}/bin/context7-mcp";
        description =
          "Context 7 MCP server for enhanced context management and analysis";
      };
      gcloud = {
        command = "npx";
        args = [ "-y" "@google-cloud/gcloud-mcp" ];
      };
      git = {
        command = "${pkgs.mcp-server-git}/bin/mcp-server-git";
        description =
          "Git operations for the repository including status, diff, log, and branch management";
      };
      github = {
        command = "npx";
        args = [ "-y" "@modelcontextprotocol/server-github" ];
        description =
          "GitHub integration for managing issues, pull requests, and repository operations";
      };
      kubectl = {
        command = "${pkgs.kubectl-mcp-server}/bin/kubectl-mcp-server";
        description = "kubectl for managing and debugging Kubernetes clusters";
      };
      memory = {
        command = "npx";
        args = [ "-y" "@modelcontextprotocol/server-memory" ];
        description =
          "Persistent memory for storing context about the project across sessions";
      };
      "sequential-thinking" = {
        command = "npx";
        args = [ "-y" "@modelcontextprotocol/server-sequential-thinking" ];
        description =
          "Enhanced reasoning capabilities for complex architectural and debugging tasks";
      };
    };
  };
}
