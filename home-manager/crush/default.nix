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
  cfg = config.programs.mcp;

  # MCP servers for Crush. Import shared definitions and ensure `type` is specified.
  # Crush requires `type = "stdio"` for command-based servers.
  mcpServers =
    let
      servers =
        (import ../mcp/servers.nix {
          inherit
            pkgs
            lib
            cfg
            config
            ;
        }).mcpServers;
    in
    lib.mapAttrs (
      _name: value: if (value ? command && !(value ? type)) then value // { type = "stdio"; } else value
    ) servers;

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

  mucieModels = [
    {
      id = "gemma-4-26b-a4b-it-4bit";
      name = "gemma4:e4b (omlx @mucie)";
    }
  ];

  # Self-hosted Ollama instance. Uses Ollama's OpenAI-compatible endpoint
  # so we declare provider type "openai" with a custom base_url.
  # context_window is set to 65536 which requires Ollama to run with
  # `num_ctx >= 65536`. On lucie KV cache is quantized to q8_0 and flash
  # attention is enabled (see hosts/lucie/default.nix), so a 64k cache
  # fits fully on the RTX 5090's 32 GB VRAM alongside the model weights.
  lucieModels = [
    {
      id = "gemma4:31b";
      name = "Gemma 4 31B (ollama @lucie)";
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
      lucie = {
        type = "openai";
        base_url = "http://10.100.0.100:11434/v1";
        api_key = "ollama";
        models = lucieModels;
      };
      mucie = {
        type = "openai";
        base_url = "http://127.0.0.1:8000/v1";
        api_key = "asdfasdf";
        models = mucieModels;
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
    options = {
      tui = {
        # Start in compact layout (sidebar hidden). Toggle at runtime with
        # Ctrl+P -> "Toggle Sidebar" (visible only when terminal >= 120 cols).
        compact_mode = true;
      };
      attribution = {
        generated_with = false;
        trailer_style = "none";
      };
    };
  };
in
{
  home.packages = [ pkgs.crush ];

  xdg.configFile."zsh/crush.zsh".text = ''
    alias crush="crush --yolo"
  '';

  xdg.configFile."crush/crush.json".text = builtins.toJSON crushConfig;
}
