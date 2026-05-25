{
  pkgs,
  lib,
  cfg,
  config,
}:
let
  mcp-server-github-wrapper = pkgs.callPackage ./mcp-server-github-wrapper.nix { inherit config; };
  mcp-server-kubectl-wrapper = pkgs.callPackage ./mcp-server-kubectl-wrapper.nix { };
in
{
  mcpServers =
    { }
    // (lib.optionalAttrs cfg.enableAtlassian {
      atlassian = {
        command = "${pkgs.gotha.mcp-atlassian}/bin/mcp-atlassian";
        args = [
          "--env-file"
          "~/.env"
        ];
        description = "Atlassian MCP server for managing JIRA projects and issues, and Confluence content";
      };
    })
    // (lib.optionalAttrs cfg.enableDissona {
      dissona = {
        command = "npx";
        args = [
          "-y"
          "mcp-remote"
          "https://dissona.hgeorgiev.com/mcp/sse"
        ];
        description = "Dissona MCP server";
      };
    })
    // (lib.optionalAttrs cfg.enableContext7 {
      "context-7" = {
        command = "${pkgs.context7-mcp}/bin/context7-mcp";
        description = "Context 7 MCP server for enhanced context management and analysis";
      };
    })
    // (lib.optionalAttrs cfg.enableGcloud {
      gcloud = {
        command = "${pkgs.gotha.gcloud-mcp}/bin/gcloud-mcp";
        description = "Google Cloud Platform (GCP) integration for managing resources and services";
      };
    })
    // (lib.optionalAttrs cfg.enableGit {
      git = {
        command = "${pkgs.mcp-server-git}/bin/mcp-server-git";
        description = "Git operations for the repository including status, diff, log, and branch management";
      };
    })
    // (lib.optionalAttrs cfg.enableGithub {
      github = {
        command = "${mcp-server-github-wrapper}/bin/mcp-server-github-wrapper";
        description = "GitHub integration for managing issues, pull requests, and repository operations";
      };
    })
    // (lib.optionalAttrs cfg.enableKubectl {
      kubectl = {
        command = "${mcp-server-kubectl-wrapper}/bin/mcp-server-kubectl-wrapper";
        description = "kubectl for managing and debugging Kubernetes clusters";
      };
    })
    // (lib.optionalAttrs cfg.enableMemory {
      memory = {
        command = "${pkgs.mcp-server-memory}/bin/mcp-server-memory";
        description = "Persistent memory for storing context about the project across sessions";
      };
    })
    // (lib.optionalAttrs cfg.enablePlaywright {
      playwright = {
        command = "${pkgs.playwright-mcp}/bin/playwright-mcp";
        description = "Playwright server for browser automation and web testing";
      };
    })
    // (lib.optionalAttrs cfg.enableSequentialThinking {
      "sequential-thinking" = {
        command = "${pkgs.mcp-server-sequential-thinking}/bin/mcp-server-sequential-thinking";
        description = "Enhanced reasoning capabilities for complex architectural and debugging tasks";
      };
    })
    // (lib.optionalAttrs cfg.enableGrafana {
      "Grafana" = {
        url = "https://grafana-mcp-internal.qa-prometheus.qa.redislabs.com/sse";
        type = "sse";
      };
    })
    // (lib.optionalAttrs cfg.enableTempo {
      "tempo-mcp" = {
        url = "https://tempo-query-internal.qa-prometheus-extras.qa.redislabs.com/api/mcp";
        type = "http";
      };
    });
}
