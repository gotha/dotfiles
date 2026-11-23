# LiteLLM - unified LLM API proxy, run from the upstream container image beside
# a postgres container for its request log, rather than through the nixpkgs
# services.litellm module. Network access is restricted by firewall to local
# networks only.
#
# Split out of ../../../hosts/lucie so a host can have the proxy without taking
# the rest of lucie with it. custom.masterKeyFile is the one thing the module
# cannot supply itself: a file holding the admin UI / proxy auth key. The host
# decides where that file comes from - on lucie it is a sops secret - so how it
# gets decrypted stays out of here, and so does the ordering against whatever
# unit does the decrypting.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.litellm.custom;
  modelListYaml = if cfg.modelList == "" then "[]" else "\n${cfg.modelList}";
in
{
  options.services.litellm.custom = {
    port = lib.mkOption {
      type = lib.types.port;
      default = 14000;
      description = ''
        Host port the proxy listens on; the container always serves 4000
        behind it. The firewall rules below follow whatever this is set to.
      '';
    };

    masterKeyFile = lib.mkOption {
      type = lib.types.path;
      example = "/run/secrets/litellm_master_key";
      description = ''
        File holding the LiteLLM master key, read at service start and handed to
        the container as LITELLM_MASTER_KEY. The service runs as root, so the
        file need not be readable by anyone else.
      '';
    };

    modelList = lib.mkOption {
      type = lib.types.lines;
      default = "";
      example = ''
        - model_name: gemma3:4b
          litellm_params:
            model: ollama/gemma3:4b
            api_base: http://host.docker.internal:11434
      '';
      description = ''
        YAML sequence spliced under `model_list:` in /etc/litellm/config.yaml.
        Nix splices a multi-line string verbatim rather than re-indenting it, so
        write entries flush left, starting at `- model_name:`; a sequence may sit
        level with its key. Left empty the proxy comes up with `model_list: []`
        and serves no models.
      '';
    };

    databaseUrl = lib.mkOption {
      type = lib.types.str;
      default = "os.environ/DATABASE_URL";
      description = ''
        general_settings.database_url. The default defers to the DATABASE_URL
        the unit already passes the container, pointing at the postgres beside
        it; override to send the request log somewhere else.
      '';
    };

    requestTimeout = lib.mkOption {
      type = lib.types.int;
      default = 600;
      description = "litellm_settings.request_timeout, in seconds.";
    };

    dropParams = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        litellm_settings.drop_params. Drops parameters a model does not accept
        instead of erroring, which is what lets one OpenAI-shaped request reach
        backends that differ in what they support.
      '';
    };
  };

  config = {
    # Enable Docker
    virtualisation.docker.enable = true;

    # Create data directories
    # PostgreSQL in Alpine container runs as UID 70 (postgres user)
    systemd.tmpfiles.rules = [
      "d /var/lib/litellm 0755 root root -"
      "d /var/lib/litellm/postgres 0700 70 70 -"
    ];

    # LiteLLM configuration file. model_list comes from the host; everything
    # else has a default here that the host may override.
    environment.etc."litellm/config.yaml".text = ''
      model_list: ${modelListYaml}

      general_settings:
        database_url: ${cfg.databaseUrl}

      litellm_settings:
        request_timeout: ${toString cfg.requestTimeout}
        drop_params: ${lib.boolToString cfg.dropParams}
    '';

    # LiteLLM stack (PostgreSQL + LiteLLM) as a single systemd service
    systemd.services.litellm = {
      description = "LiteLLM Proxy with PostgreSQL";
      after = [
        "docker.service"
        "network-online.target"
      ];
      requires = [ "docker.service" ];
      wants = [ "network-online.target" ];
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

        # Read master key from the file the host pointed us at
        MASTER_KEY=$(cat ${cfg.masterKeyFile})

        # Start LiteLLM
        exec ${pkgs.docker}/bin/docker run \
          --name litellm \
          --network litellm-net \
          --rm \
          -e DATABASE_URL=postgresql://litellm:litellm@litellm-postgres:5432/litellm \
          -e LITELLM_MASTER_KEY="$MASTER_KEY" \
          -v /etc/litellm/config.yaml:/app/config.yaml:ro \
          -p ${toString cfg.port}:4000 \
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
      iptables -A INPUT -p tcp --dport ${toString cfg.port} -s 127.0.0.1 -j ACCEPT
      # Allow LiteLLM from 192.168.0.0/16
      iptables -A INPUT -p tcp --dport ${toString cfg.port} -s 192.168.0.0/16 -j ACCEPT
      # Allow LiteLLM from 10.100.0.0/24 (WireGuard)
      iptables -A INPUT -p tcp --dport ${toString cfg.port} -s 10.100.0.0/24 -j ACCEPT
      # Drop all other traffic to LiteLLM port
      iptables -A INPUT -p tcp --dport ${toString cfg.port} -j DROP
    '';
  };
}
