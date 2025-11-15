{ pkgs, config, ... }:
let
  mcp-server-github-wrapper =
    pkgs.callPackage ./mcp-server-github-wrapper.nix { inherit config; };
in {

  home.packages = with pkgs; [
    context7-mcp
    gcloud-mcp
    kubectl-mcp-server
    mcp-atlassian
    mcp-server-git
    mcp-server-github-wrapper
    mcp-server-memory
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
        command = "${pkgs.gcloud-mcp}/bin/gcloud-mcp";
        description =
          "Google Cloud Platform (GCP) integration for managing resources and services";
      };
      git = {
        command = "${pkgs.mcp-server-git}/bin/mcp-server-git";
        description =
          "Git operations for the repository including status, diff, log, and branch management";
      };
      github = {
        command = "${mcp-server-github-wrapper}/bin/mcp-server-github-wrapper";
        description =
          "GitHub integration for managing issues, pull requests, and repository operations";
      };
      kubectl = {
        command = "${pkgs.kubectl-mcp-server}/bin/kubectl-mcp-server";
        description = "kubectl for managing and debugging Kubernetes clusters";
      };
      memory = {
        command = "${pkgs.mcp-server-memory}/bin/mcp-server-memory";
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
