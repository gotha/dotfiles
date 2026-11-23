{ config, ... }:
{
  imports = [ ../../os/nixos/services/litellm.nix ];

  sops.secrets.litellm_master_key = {
    sopsFile = ./secrets/litellm.enc.json;
    format = "json";
    key = "master_key";
    mode = "0400";
  };

  services.litellm.custom = {
    masterKeyFile = config.sops.secrets.litellm_master_key.path;

    # Flush left on purpose: this is spliced under `model_list:` verbatim, and
    # a YAML sequence may sit level with its key. Indenting it here would
    # indent it there too.
    modelList = ''
      - model_name: gemma4:31b
        litellm_params:
          model: ollama/gemma4:31b
          api_base: http://host.docker.internal:11434
          timeout: 600
        model_info:
          input_cost_per_token: 0.0000025
          output_cost_per_token: 0.00001

      - model_name: gemma4:26b
        litellm_params:
          model: ollama/gemma4:26b
          api_base: http://host.docker.internal:11434
          timeout: 600
        model_info:
          input_cost_per_token: 0.0000025
          output_cost_per_token: 0.00001

      - model_name: gemma3:4b
        litellm_params:
          model: ollama/gemma3:4b
          api_base: http://host.docker.internal:11434
          timeout: 600
        model_info:
          input_cost_per_token: 0.000001
          output_cost_per_token: 0.000004

      - model_name: qwen3-coder-next:q4_K_M
        litellm_params:
          model: ollama/qwen3-coder-next:q4_K_M
          api_base: http://host.docker.internal:11434
          timeout: 600
        model_info:
          input_cost_per_token: 0.000001
          output_cost_per_token: 0.000004

      - model_name: qwen3-coder:30b-a3b-q4_K_M
        litellm_params:
          model: ollama/qwen3-coder:30b-a3b-q4_K_M
          api_base: http://host.docker.internal:11434
          timeout: 600
        model_info:
          input_cost_per_token: 0.000001
          output_cost_per_token: 0.000004
    '';
  };

  # The key does not exist until sops-nix has decrypted it.
  systemd.services.litellm.after = [ "sops-nix.service" ];
}
