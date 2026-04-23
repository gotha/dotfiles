# OpenCode configuration with Ollama provider and MCP servers
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

  # Build MCP servers configuration for OpenCode
  # OpenCode requires "type": "local" and "command" as an array
  mcpServers =
    { }
    // (lib.optionalAttrs cfg.enableContext7 {
      context7 = {
        type = "local";
        command = [ "${pkgs.context7-mcp}/bin/context7-mcp" ];
      };
    })
    // (lib.optionalAttrs cfg.enableGit {
      git = {
        type = "local";
        command = [ "${pkgs.mcp-server-git}/bin/mcp-server-git" ];
      };
    })
    // (lib.optionalAttrs cfg.enableGithub {
      github = {
        type = "local";
        command = [ "${mcp-server-github-wrapper}/bin/mcp-server-github-wrapper" ];
      };
    })
    // (lib.optionalAttrs cfg.enableKubectl {
      kubectl = {
        type = "local";
        command = [ "${mcp-server-kubectl-wrapper}/bin/mcp-server-kubectl-wrapper" ];
      };
    })
    // (lib.optionalAttrs cfg.enableMemory {
      memory = {
        type = "local";
        command = [ "${pkgs.mcp-server-memory}/bin/mcp-server-memory" ];
      };
    })
    // (lib.optionalAttrs cfg.enablePlaywright {
      playwright = {
        type = "local";
        command = [ "${pkgs.mcp-server-playwright}/bin/mcp-server-playwright" ];
      };
    })
    // (lib.optionalAttrs cfg.enableSequentialThinking {
      sequential_thinking = {
        type = "local";
        command = [ "${pkgs.mcp-server-sequential-thinking}/bin/mcp-server-sequential-thinking" ];
      };
    });
in
{
  # OpenCode configuration file
  xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    provider = {
      ollama = {
        options = {
          baseURL = "http://localhost:11434/v1";
        };
        models = {
          "qwen3-coder:30b" = { };
          "qwen3.5:35b-a3b" = { };
        };
      };
    };
    mcp = mcpServers;
  };
}
