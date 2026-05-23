{
  pkgs,
  config,
  lib,
  ...
}:
let
  mcp-server-kubectl-wrapper = pkgs.callPackage ./mcp-server-kubectl-wrapper.nix { };

  cfg = config.programs.mcp;

  inherit
    (import ./servers.nix {
      inherit
        pkgs
        lib
        cfg
        config
        ;
    })
    mcpServers
    ;

  # Conditionally build package list based on enabled servers.
  # Packages from upstream nixpkgs live at `pkgs.*`; packages from the
  # gotha/nixpkgs flake live under the `pkgs.gotha.*` namespace.
  packages =
    with pkgs;
    (lib.optionals cfg.enableAtlassian [ gotha.mcp-atlassian ])
    ++ (lib.optionals cfg.enableContext7 [ context7-mcp ])
    ++ (lib.optionals cfg.enableGcloud [ gotha.gcloud-mcp ])
    ++ (lib.optionals cfg.enableGit [ mcp-server-git ])
    ++ (lib.optionals cfg.enableGithub [
      (pkgs.callPackage ./mcp-server-github-wrapper.nix { inherit config; })
    ])
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
    inherit mcpServers;
  };

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
    home.packages = packages;

    xdg.configFile."mcp/mcp.json".text = mcpConfigJSON;
    home.file.".cursor/mcp.json".text = mcpConfigJSON;
  };
}
