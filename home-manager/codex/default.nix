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
  mcp-server-kubectl-wrapper = pkgs.callPackage ../mcp/mcp-server-kubectl-wrapper.nix { };

  cfg = config.programs.mcp;

  # Build MCP servers configuration for Codex.
  # Codex reads ~/.codex/config.toml with [mcp_servers.<name>] tables.
  # STDIO servers use `command`/`args`; remote servers use `url`.
  mcpServers =
    { }
    // (lib.optionalAttrs cfg.enableContext7 {
      "context-7" = {
        command = "${pkgs.context7-mcp}/bin/context7-mcp";
      };
    })
    // (lib.optionalAttrs cfg.enableGcloud {
      gcloud = {
        command = "${pkgs.gotha.gcloud-mcp}/bin/gcloud-mcp";
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
        command = "${mcp-server-kubectl-wrapper}/bin/mcp-server-kubectl-wrapper";
      };
    })
    // (lib.optionalAttrs cfg.enableMemory {
      memory = {
        command = "${pkgs.mcp-server-memory}/bin/mcp-server-memory";
      };
    })
    // (lib.optionalAttrs cfg.enablePlaywright {
      playwright = {
        command = "${pkgs.playwright-mcp}/bin/playwright-mcp";
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

  generatedConfig = tomlFormat.generate "codex-config.toml" {
    mcp_servers = mcpServers;

    # fix my tmux scroll
    tui.alternate_screen = "never";

    # No prompts, no sandbox - the same grant as
    # --dangerously-bypass-approvals-and-sandbox.
    approval_policy = "never";
    sandbox_mode = "danger-full-access";
    # Empty so the merge prunes it: inert under danger-full-access, but left
    # behind it would quietly reapply if sandbox_mode ever went back.
    sandbox_workspace_write = { };
  };

  pythonWithToml = pkgs.python3.withPackages (ps: [ ps.tomli-w ]);
in
{
  home = {
    packages = [ pkgs.codex ];

    # Not home.file: Codex writes to config.toml, and against a store path its
    # trust prompt fails with "failed to persist config ... (code -32603)".
    # This merges the Nix-owned tables into a real file instead, leaving
    # [projects] and anything else Codex persists alone. After linkGeneration
    # so the symlink from the generation that did use home.file is already gone.
    activation.codexConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      run ${pythonWithToml}/bin/python3 ${./merge-config.py} \
        ${generatedConfig} "$HOME/.codex/config.toml"
    '';
  };
}
