# Crush CLI (charmbracelet) configuration with OpenAI Codex models and MCP.
#
# Crush reads config from $HOME/.config/crush/crush.json (or .crush.json in
# the project). We override the built-in `openai` provider to register the
# latest Codex model IDs and default the large/small slots to them.
#
# OPENAI_API_KEY must be exported in the shell that runs `crush`.
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

  # MCP servers for Crush. Transport `type` is required:
  # - stdio: `command` + optional `args`
  # - http/sse: `url` + optional `headers`
  mcpServers =
    { }
    // (lib.optionalAttrs cfg.enableAtlassian {
      atlassian = {
        type = "stdio";
        command = "${pkgs.mcp-atlassian}/bin/mcp-atlassian";
        args = [
          "--env-file"
          "${config.home.homeDirectory}/.env"
        ];
      };
    })
    // (lib.optionalAttrs cfg.enableContext7 {
      "context-7" = {
        type = "stdio";
        command = "${pkgs.context7-mcp}/bin/context7-mcp";
      };
    })
    // (lib.optionalAttrs cfg.enableGcloud {
      gcloud = {
        type = "stdio";
        command = "${pkgs.gcloud-mcp}/bin/gcloud-mcp";
      };
    })
    // (lib.optionalAttrs cfg.enableGit {
      git = {
        type = "stdio";
        command = "${pkgs.mcp-server-git}/bin/mcp-server-git";
      };
    })
    // (lib.optionalAttrs cfg.enableGithub {
      github = {
        type = "stdio";
        command = "${mcp-server-github-wrapper}/bin/mcp-server-github-wrapper";
      };
    })
    // (lib.optionalAttrs cfg.enableKubectl {
      kubectl = {
        type = "stdio";
        command = "${pkgs.kubectl-mcp-server}/bin/kubectl-mcp-server";
      };
    })
    // (lib.optionalAttrs cfg.enableMemory {
      memory = {
        type = "stdio";
        command = "${pkgs.mcp-server-memory}/bin/mcp-server-memory";
      };
    })
    // (lib.optionalAttrs cfg.enablePlaywright {
      playwright = {
        type = "stdio";
        command = "${pkgs.mcp-server-playwright}/bin/mcp-server-playwright";
      };
    })
    // (lib.optionalAttrs cfg.enableSequentialThinking {
      "sequential-thinking" = {
        type = "stdio";
        command = "${pkgs.mcp-server-sequential-thinking}/bin/mcp-server-sequential-thinking";
      };
    })
    // (lib.optionalAttrs cfg.enableGrafana {
      Grafana = {
        type = "sse";
        url = "https://grafana-mcp-internal.qa-prometheus.qa.redislabs.com/sse";
      };
    })
    // (lib.optionalAttrs cfg.enableTempo {
      "tempo-mcp" = {
        type = "http";
        url = "https://tempo-query-internal.qa-prometheus-extras.qa.redislabs.com/api/mcp";
      };
    });

  # Latest Codex-family models as of 2026-04. gpt-5.1-codex is the current
  # API-available Codex model; gpt-5.1 is the general-purpose counterpart
  # used as the "small" slot for lighter tasks.
  openaiModels = [
    {
      id = "gpt-5.1-codex";
      name = "GPT-5.1 Codex";
      context_window = 400000;
      default_max_tokens = 128000;
      can_reason = true;
      has_reasoning_efforts = true;
      default_reasoning_effort = "medium";
      supports_attachments = true;
    }
    {
      id = "gpt-5.1";
      name = "GPT-5.1";
      context_window = 400000;
      default_max_tokens = 128000;
      can_reason = true;
      has_reasoning_efforts = true;
      default_reasoning_effort = "medium";
      supports_attachments = true;
    }
  ];

  # Self-hosted Ollama instance. Uses Ollama's OpenAI-compatible endpoint
  # so we declare provider type "openai" with a custom base_url.
  # context_window is set to 65536 which requires Ollama to run with
  # `num_ctx >= 65536`. On lucie KV cache is quantized to q8_0 and flash
  # attention is enabled (see hosts/lucie/default.nix), so a 64k cache
  # fits fully on the RTX 5090's 32 GB VRAM alongside the model weights.
  ollamaModels = [
    {
      id = "gemma4:31b";
      name = "Gemma 4 31B (Ollama @ lucie)";
      context_window = 65536;
      default_max_tokens = 4096;
    }
  ];

  crushConfig = {
    "$schema" = "https://charm.land/crush.json";
    providers = {
      openai = {
        type = "openai";
        api_key = "$OPENAI_API_KEY";
        models = openaiModels;
      };
      ollama = {
        type = "openai";
        base_url = "http://10.100.0.100:11434/v1";
        api_key = "ollama";
        models = ollamaModels;
      };
    };
    models = {
      large = {
        model = "gpt-5.1-codex";
        provider = "openai";
      };
      small = {
        model = "gpt-5.1";
        provider = "openai";
      };
    };
    mcp = mcpServers;
  };
in
{
  home.packages = [ pkgs.crush ];

  xdg.configFile."crush/crush.json".text = builtins.toJSON crushConfig;
}
