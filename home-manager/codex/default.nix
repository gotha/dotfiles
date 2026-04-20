# Codex CLI configuration with MCP servers
{
  config,
  pkgs,
  lib,
  ...
}:
let
  mcp-server-github-wrapper = pkgs.callPackage ../mcp/mcp-server-github-wrapper.nix {
    inherit config;
  };

  cfg = config.programs.mcp;

  # Build MCP servers configuration for Codex.
  # Codex reads ~/.codex/config.toml with [mcp_servers.<name>] tables.
  # STDIO servers use `command`/`args`; remote servers use `url`.
  mcpServers =
    { }
    // (lib.optionalAttrs cfg.enableAtlassian {
      atlassian = {
        command = "${pkgs.mcp-atlassian}/bin/mcp-atlassian";
        args = [
          "--env-file"
          "${config.home.homeDirectory}/.env"
        ];
      };
    })
    // (lib.optionalAttrs cfg.enableContext7 {
      "context-7" = {
        command = "${pkgs.context7-mcp}/bin/context7-mcp";
      };
    })
    // (lib.optionalAttrs cfg.enableGcloud {
      gcloud = {
        command = "${pkgs.gcloud-mcp}/bin/gcloud-mcp";
      };
    })
    // (lib.optionalAttrs cfg.enableGit {
      git = {
        command = "${pkgs.mcp-server-git}/bin/mcp-server-git";
      };
    })
    // (lib.optionalAttrs cfg.enableGithub {
      github = {
        command = "${mcp-server-github-wrapper}/bin/mcp-server-github-wrapper";
      };
    })
    // (lib.optionalAttrs cfg.enableKubectl {
      kubectl = {
        command = "${pkgs.kubectl-mcp-server}/bin/kubectl-mcp-server";
      };
    })
    // (lib.optionalAttrs cfg.enableMemory {
      memory = {
        command = "${pkgs.mcp-server-memory}/bin/mcp-server-memory";
      };
    })
    // (lib.optionalAttrs cfg.enablePlaywright {
      playwright = {
        command = "${pkgs.mcp-server-playwright}/bin/mcp-server-playwright";
      };
    })
    // (lib.optionalAttrs cfg.enableSequentialThinking {
      "sequential-thinking" = {
        command = "${pkgs.mcp-server-sequential-thinking}/bin/mcp-server-sequential-thinking";
      };
    })
    // (lib.optionalAttrs cfg.enableGrafana {
      Grafana = {
        url = "https://grafana-mcp-internal.qa-prometheus.qa.redislabs.com/sse";
      };
    })
    // (lib.optionalAttrs cfg.enableTempo {
      "tempo-mcp" = {
        url = "https://tempo-query-internal.qa-prometheus-extras.qa.redislabs.com/api/mcp";
      };
    });

  tomlFormat = pkgs.formats.toml { };
in
{
  home.packages = [ pkgs.codex ];

  home.file.".codex/config.toml".source = tomlFormat.generate "codex-config.toml" {
    mcp_servers = mcpServers;
  };
}
