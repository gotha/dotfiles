# LiteLLM - Unified LLM API proxy running in Docker
# No authentication - access restricted by firewall to local networks only
{ config, pkgs, ... }:

let
  litellmPort = 14000;
in
{
  # Enable Docker
  virtualisation.docker.enable = true;

  # Create data directories
  # PostgreSQL in Alpine container runs as UID 70 (postgres user)
  systemd.tmpfiles.rules = [
    "d /var/lib/litellm 0755 root root -"
    "d /var/lib/litellm/postgres 0700 70 70 -"
  ];

  # LiteLLM configuration file
  environment.etc."litellm/config.yaml".text = ''
    model_list:
      - model_name: gemma4:31b
        litellm_params:
          model: ollama/gemma4:31b
          api_base: http://host.docker.internal:11434
          timeout: 600
        model_info:
          input_cost_per_token: 0.0000025
          output_cost_per_token: 0.00001

    general_settings:
      database_url: os.environ/DATABASE_URL

    litellm_settings:
      request_timeout: 600
      drop_params: true
  '';

  # LiteLLM stack (PostgreSQL + LiteLLM) as a single systemd service
  systemd.services.litellm = {
    description = "LiteLLM Proxy with PostgreSQL";
    after = [
      "docker.service"
      "network-online.target"
    ];
    requires = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = 10;
    };

    script = ''
      # Create network if it doesn't exist
      ${pkgs.docker}/bin/docker network inspect litellm-net >/dev/null 2>&1 || \
        ${pkgs.docker}/bin/docker network create litellm-net

      # Stop and remove existing containers
      ${pkgs.docker}/bin/docker stop litellm-postgres litellm 2>/dev/null || true
      ${pkgs.docker}/bin/docker rm litellm-postgres litellm 2>/dev/null || true

      # Start PostgreSQL
      ${pkgs.docker}/bin/docker run -d \
        --name litellm-postgres \
        --network litellm-net \
        --restart unless-stopped \
        -e POSTGRES_DB=litellm \
        -e POSTGRES_USER=litellm \
        -e POSTGRES_PASSWORD=litellm \
        -v /var/lib/litellm/postgres:/var/lib/postgresql/data \
        --health-cmd="pg_isready -U litellm" \
        --health-interval=10s \
        --health-timeout=5s \
        --health-retries=5 \
        postgres:16-alpine

      # Wait for PostgreSQL to be ready
      echo "Waiting for PostgreSQL to be ready..."
      sleep 10

      # Start LiteLLM
      exec ${pkgs.docker}/bin/docker run \
        --name litellm \
        --network litellm-net \
        --rm \
        -e DATABASE_URL=postgresql://litellm:litellm@litellm-postgres:5432/litellm \
        -v /etc/litellm/config.yaml:/app/config.yaml:ro \
        -p ${toString litellmPort}:4000 \
        --add-host=host.docker.internal:host-gateway \
        ghcr.io/berriai/litellm:main-latest \
        --config /app/config.yaml --host 0.0.0.0 --port 4000
    '';

    preStop = ''
      ${pkgs.docker}/bin/docker stop litellm litellm-postgres 2>/dev/null || true
      ${pkgs.docker}/bin/docker rm litellm litellm-postgres 2>/dev/null || true
    '';
  };

  # Firewall - only allow access from localhost, 192.168.*.* and 10.100.0.*
  networking.firewall.extraCommands = ''
    # Allow LiteLLM from localhost
    iptables -A INPUT -p tcp --dport ${toString litellmPort} -s 127.0.0.1 -j ACCEPT
    # Allow LiteLLM from 192.168.0.0/16
    iptables -A INPUT -p tcp --dport ${toString litellmPort} -s 192.168.0.0/16 -j ACCEPT
    # Allow LiteLLM from 10.100.0.0/24 (WireGuard)
    iptables -A INPUT -p tcp --dport ${toString litellmPort} -s 10.100.0.0/24 -j ACCEPT
    # Drop all other traffic to LiteLLM port
    iptables -A INPUT -p tcp --dport ${toString litellmPort} -j DROP
  '';
}
