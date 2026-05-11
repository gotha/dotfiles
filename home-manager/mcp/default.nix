{
  pkgs,
  config,
  lib,
  ...
}:
let
  mcp-server-github-wrapper = pkgs.callPackage ./mcp-server-github-wrapper.nix { inherit config; };
  mcp-server-kubectl-wrapper = pkgs.callPackage ./mcp-server-kubectl-wrapper.nix { };

  cfg = config.programs.mcp;

  # Conditionally build package list based on enabled servers.
  # Packages from upstream nixpkgs live at `pkgs.*`; packages from the
  # gotha/nixpkgs flake live under the `pkgs.gotha.*` namespace.
  allPackages =
    with pkgs;
    (lib.optionals cfg.enableAtlassian [ gotha.mcp-atlassian ])
    ++ (lib.optionals cfg.enableContext7 [ context7-mcp ])
    ++ (lib.optionals cfg.enableGcloud [ gotha.gcloud-mcp ])
    ++ (lib.optionals cfg.enableGit [ mcp-server-git ])
    ++ (lib.optionals cfg.enableGithub [ mcp-server-github-wrapper ])
    ++ (lib.optionals cfg.enableKubectl [ mcp-server-kubectl-wrapper ])
    # mcp-server-memory and mcp-server-sequential-thinking both ship
    # `lib/node_modules/@modelcontextprotocol/servers/dist/index.js`
    # (different content per package). lib.hiPrio resolves the buildEnv
    # conflict; each binary uses its own store path's lib/ at runtime.
    ++ (lib.optionals cfg.enableMemory [ (lib.hiPrio mcp-server-memory) ])
    ++ (lib.optionals cfg.enablePlaywright [ playwright-mcp ])
    ++ (lib.optionals cfg.enableSequentialThinking [ mcp-server-sequential-thinking ]);

  # Conditionally build servers configuration
  mcpConfigJSON = builtins.toJSON {
    "$schema" = "https://modelcontextprotocol.io/schema/mcp.json";
    mcpServers = allServers;
  };

  allServers =
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
in
{

  options.programs.mcp = {
    enableAtlassian = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable MCP Atlassian server integration (JIRA and Confluence)";
    };

    enableContext7 = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable MCP Context 7 server for enhanced context management";
    };

    enableGcloud = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable MCP Google Cloud Platform (GCP) server integration";
    };

    enableGit = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable MCP Git server for repository operations";
    };

    enableGithub = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable MCP GitHub server integration";
    };

    enableGrafana = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable MCP Grafana server for querying metrics and dashboards";
    };

    enableKubectl = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable MCP kubectl server for Kubernetes cluster management";
    };

    enableMemory = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable MCP Memory server for persistent context storage";
    };

    enablePlaywright = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable MCP Playwright server for browser automation and web testing";
    };

    enableSequentialThinking = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable MCP Sequential Thinking server for enhanced reasoning";
    };

    enableTempo = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable MCP Tempo server for querying metrics";
    };
  };

  config = {
    home.packages = allPackages;

    xdg.configFile."mcp/mcp.json".text = mcpConfigJSON;
    home.file.".cursor/mcp.json".text = mcpConfigJSON;
  };
}
