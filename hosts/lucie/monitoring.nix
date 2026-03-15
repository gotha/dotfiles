{
  pkgs,
  config,
  ...
}:
{
  # Sops configuration for system-level secrets
  # Use Age key derived from SSH host key (default sops-nix behavior)
  # ============================================================================
  # TimescaleDB (PostgreSQL with TimescaleDB extension)
  # ============================================================================
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;

    # Use port 35432 to avoid conflicts with Docker PostgreSQL instances
    settings = {
      port = 35432;
      # TimescaleDB tuning
      shared_preload_libraries = "timescaledb";
      # Memory settings (adjust based on available RAM)
      shared_buffers = "256MB";
      effective_cache_size = "1GB";
      work_mem = "16MB";
      maintenance_work_mem = "128MB";
    };

    # Enable TimescaleDB extension
    extensions = ps: [ ps.timescaledb ];

    # Initialize database and users
    ensureDatabases = [ "monitoring" ];
    ensureUsers = [
      {
        name = "telegraf";
      }
      {
        name = "grafana";
      }
    ];

    # Grant permissions after initialization
    initialScript = pkgs.writeText "init-monitoring-db.sql" ''
      -- Grant telegraf user permissions
      GRANT ALL PRIVILEGES ON DATABASE monitoring TO telegraf;

      -- Grant grafana user read-only permissions
      GRANT CONNECT ON DATABASE monitoring TO grafana;
    '';
  };

  # Set passwords from sops secrets after PostgreSQL starts
  systemd.services.postgresql-setup-monitoring = {
    description = "Set up monitoring database passwords";
    after = [ "postgresql.service" ];
    requires = [ "postgresql.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
      RemainAfterExit = true;
    };

    script = ''
      # Wait for PostgreSQL to be ready
      while ! ${pkgs.postgresql_16}/bin/pg_isready -p 35432 -q; do
        sleep 1
      done

      # Set telegraf password
      ${pkgs.postgresql_16}/bin/psql -p 35432 -c "ALTER USER telegraf WITH PASSWORD '$(cat ${config.sops.secrets.telegraf_db_password.path})';"

      # Set grafana password
      ${pkgs.postgresql_16}/bin/psql -p 35432 -c "ALTER USER grafana WITH PASSWORD '$(cat ${config.sops.secrets.grafana_db_password.path})';"

      # Enable TimescaleDB extension in monitoring database
      ${pkgs.postgresql_16}/bin/psql -p 35432 -d monitoring -c "CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;"

      # Grant telegraf full access to create tables and write data
      ${pkgs.postgresql_16}/bin/psql -p 35432 -d monitoring -c "GRANT ALL ON SCHEMA public TO telegraf;"
      ${pkgs.postgresql_16}/bin/psql -p 35432 -d monitoring -c "GRANT ALL ON ALL TABLES IN SCHEMA public TO telegraf;"
      ${pkgs.postgresql_16}/bin/psql -p 35432 -d monitoring -c "GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO telegraf;"
      ${pkgs.postgresql_16}/bin/psql -p 35432 -d monitoring -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO telegraf;"
      ${pkgs.postgresql_16}/bin/psql -p 35432 -d monitoring -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO telegraf;"

      # Grant grafana read access to all tables in monitoring database
      ${pkgs.postgresql_16}/bin/psql -p 35432 -d monitoring -c "GRANT USAGE ON SCHEMA public TO grafana;"
      ${pkgs.postgresql_16}/bin/psql -p 35432 -d monitoring -c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO grafana;"
      ${pkgs.postgresql_16}/bin/psql -p 35432 -d monitoring -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO grafana;"
    '';
  };

  # Sops secrets for TimescaleDB
  sops.secrets.telegraf_db_password = {
    sopsFile = ../../secrets/timescaledb.enc.json;
    format = "json";
    key = "telegraf_password";
    owner = "postgres";
  };

  sops.secrets.grafana_db_password = {
    sopsFile = ../../secrets/timescaledb.enc.json;
    format = "json";
    key = "grafana_password";
    owner = "postgres";
  };

  # Separate secret for Grafana to read DB password
  sops.secrets.grafana_db_password_grafana = {
    sopsFile = ../../secrets/timescaledb.enc.json;
    format = "json";
    key = "grafana_password";
    owner = "grafana";
  };

  # ============================================================================
  # Telegraf (Metrics Collection)
  # ============================================================================
  services.telegraf = {
    enable = true;

    extraConfig = {
      agent = {
        interval = "10s";
        round_interval = true;
        metric_batch_size = 1000;
        metric_buffer_limit = 10000;
        collection_jitter = "0s";
        flush_interval = "10s";
        flush_jitter = "0s";
        precision = "0s";
        hostname = "lucie";
      };

      # PostgreSQL/TimescaleDB output
      outputs.postgresql = [
        {
          connection = "postgres://telegraf:$TELEGRAF_DB_PASSWORD@localhost:35432/monitoring?sslmode=disable";
          create_templates = [
            "CREATE TABLE IF NOT EXISTS {{.table}}({{.columns}})"
            "SELECT create_hypertable('{{.table}}','time',chunk_time_interval := INTERVAL '1 day',if_not_exists := TRUE)"
            "ALTER TABLE {{.table}} SET (timescaledb.compress,timescaledb.compress_segmentby='host')"
            "SELECT add_compression_policy('{{.table}}',INTERVAL '2 days',if_not_exists := TRUE)"
            "SELECT add_retention_policy('{{.table}}',INTERVAL '7 days',if_not_exists := TRUE)"
          ];
          add_column_templates = [
            "ALTER TABLE {{.table}} ADD COLUMN IF NOT EXISTS {{.column}} {{.type}}"
          ];
          tags_as_foreign_keys = false;
          uint64_type = "numeric";
        }
      ];

      # ========== INPUT PLUGINS ==========

      # System metrics
      inputs.cpu = [
        {
          percpu = true;
          totalcpu = true;
          collect_cpu_time = false;
          report_active = true;
        }
      ];

      inputs.mem = [ { } ];
      inputs.swap = [ { } ];
      inputs.system = [ { } ];
      inputs.processes = [ { } ];
      inputs.kernel = [ { } ];

      inputs.disk = [
        {
          ignore_fs = [
            "tmpfs"
            "devtmpfs"
            "devfs"
            "iso9660"
            "overlay"
            "aufs"
            "squashfs"
          ];
        }
      ];

      inputs.diskio = [ { } ];

      inputs.net = [
        {
          ignore_protocol_stats = false;
        }
      ];

      inputs.netstat = [ { } ];

      # Hardware sensors (temperatures)
      inputs.sensors = [ { } ];

      # SMART disk health
      inputs.smart = [
        {
          use_sudo = true;
        }
      ];

      # NVIDIA GPU metrics
      inputs.nvidia_smi = [
        {
          bin_path = "/run/current-system/sw/bin/nvidia-smi";
        }
      ];

      # Docker container metrics
      # NOTE: Disabled because rootless docker socket at /run/user/1000/docker.sock
      # is not accessible to the telegraf system service (permission denied on /run/user/1000/).
      # TODO: Set up TCP socket or socket proxy for rootless docker monitoring.
      # inputs.docker = [
      #   {
      #     endpoint = "unix:///run/user/1000/docker.sock";
      #     gather_services = false;
      #     source_tag = false;
      #     container_name_include = [ ];
      #     container_name_exclude = [ ];
      #     timeout = "5s";
      #   }
      # ];

      # Systemd service status
      inputs.systemd_units = [
        {
          unittype = "service";
        }
      ];

      # Per-process CPU and memory stats (top processes)
      inputs.procstat = [
        {
          # Match all processes
          pattern = ".*";
          # Collect CPU and memory stats
          pid_finder = "pgrep";
        }
      ];

      # Ollama API health check
      inputs.http_response = [
        {
          urls = [ "http://localhost:11434/api/tags" ];
          response_timeout = "5s";
          method = "GET";
          tagexclude = [
            "result_type"
            "server"
          ];
          fieldexclude = [
            "content_length"
            "response_time"
          ];
          name_override = "ollama_health";
        }
      ];

      # Ollama Prometheus metrics
      inputs.prometheus = [
        {
          urls = [ "http://localhost:11434/api/metrics" ];
          name_override = "ollama";
        }
      ];

      # Telegraf internal metrics
      inputs.internal = [
        {
          collect_memstats = true;
        }
      ];
    };
  };

  # Telegraf sops template for environment
  sops.templates."telegraf.env" = {
    content = ''
      TELEGRAF_DB_PASSWORD=${config.sops.placeholder.telegraf_db_password}
    '';
    owner = "telegraf";
  };

  # Telegraf needs docker access and password from sops
  systemd.services.telegraf = {
    path = [
      pkgs.lm_sensors
      pkgs.smartmontools
    ];
    serviceConfig = {
      # Add users group for rootless docker socket access
      SupplementaryGroups = [ "users" ];
      EnvironmentFile = config.sops.templates."telegraf.env".path;
    };
  };

  # Allow telegraf to use sudo for SMART monitoring
  security.sudo.extraRules = [
    {
      users = [ "telegraf" ];
      commands = [
        {
          command = "${pkgs.smartmontools}/bin/smartctl";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # Install smartmontools and lm_sensors for monitoring
  environment.systemPackages = [
    pkgs.smartmontools
    pkgs.lm_sensors
  ];

  # ============================================================================
  # Grafana (Visualization)
  # ============================================================================
  services.grafana = {
    enable = true;

    settings = {
      server = {
        http_addr = "0.0.0.0";
        http_port = 33000;
        domain = "lucie";
        root_url = "http://lucie:33000/";
      };

      security = {
        admin_user = "admin";
        admin_password = "$__file{${config.sops.secrets.grafana_admin_password.path}}";
        secret_key = "$__file{${config.sops.secrets.grafana_secret_key.path}}";
      };

      analytics = {
        reporting_enabled = false;
        check_for_updates = false;
      };
    };

    # Provision TimescaleDB data source
    provision = {
      enable = true;
      datasources.path = config.sops.templates."grafana-datasources.yaml".path;
      dashboards.settings.providers = [
        {
          name = "Lucie Dashboards";
          options.path = ./dashboards;
          disableDeletion = true;
        }
      ];
    };
  };

  # Use sops template to inject the password into datasource config
  sops.templates."grafana-datasources.yaml" = {
    owner = "grafana";
    content = ''
      apiVersion: 1
      deleteDatasources: []
      datasources:
        - name: TimescaleDB
          type: grafana-postgresql-datasource
          uid: timescaledb
          url: localhost:35432
          user: grafana
          access: proxy
          secureJsonData:
            password: ${config.sops.placeholder.grafana_db_password_grafana}
          jsonData:
            database: monitoring
            sslmode: disable
            postgresVersion: 1600
            timescaledb: true
          isDefault: true
          editable: false
    '';
  };

  # Grafana sops secrets
  sops.secrets.grafana_admin_password = {
    sopsFile = ../../secrets/grafana.enc.json;
    format = "json";
    key = "admin_password";
    owner = "grafana";
  };

  sops.secrets.grafana_secret_key = {
    sopsFile = ../../secrets/grafana.enc.json;
    format = "json";
    key = "secret_key";
    owner = "grafana";
  };

  # Firewall: Allow Grafana from localhost, LAN, and WireGuard
  networking.firewall = {
    allowedTCPPorts = [ 33000 ]; # Allow from all interfaces for LAN
    interfaces."wg0".allowedTCPPorts = [
      33000 # WireGuard
      35432 # Postres
    ];
  };

}
