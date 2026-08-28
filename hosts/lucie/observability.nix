# Grafana, Prometheus, Loki and Tempo - metrics, logs and traces.
#
# All four run as native NixOS services rather than containers. The modules
# exist and handle the users, state directories and unit hardening, so a
# compose file would only add moving parts.
#
# Docker services on this host reach these over host.docker.internal, which
# litellm.nix already maps to host-gateway. A container talking to that address
# arrives from the Docker bridge, which is why Loki's push API and Tempo's OTLP
# receivers bind 0.0.0.0 and the firewall admits 172.16.0.0/12 - binding
# 127.0.0.1 would be unreachable from a container.
{ config, lib, ... }:
let
  grafanaPort = 32010;
  prometheusPort = 32020;
  lokiPort = 32030;
  lokiGrpcPort = 32031;
  tempoPort = 32040;
  otlpGrpcPort = 32047;
  otlpHttpPort = 32048;

  lokiDir = "/var/lib/loki";
  tempoDir = "/var/lib/tempo";

  # Same policy as litellm.nix - localhost, LAN, WireGuard - plus the Docker
  # bridge range so containers can push logs and traces.
  allowedSources = [
    "127.0.0.1"
    "192.168.0.0/16"
    "10.100.0.0/24"
    "172.16.0.0/12"
  ];

  # Ports reachable from the allowed sources and dropped for everyone else.
  # lokiGrpcPort is deliberately absent: nothing outside this host speaks to
  # it, so it stays closed.
  exposedPorts = [
    grafanaPort
    prometheusPort
    lokiPort
    tempoPort
    otlpGrpcPort
    otlpHttpPort
  ];

  restrictPort =
    port:
    lib.concatStringsSep "\n" (
      (map (src: "iptables -A INPUT -p tcp --dport ${toString port} -s ${src} -j ACCEPT") allowedSources)
      ++ [ "iptables -A INPUT -p tcp --dport ${toString port} -j DROP" ]
    );
in
{
  # Grafana encrypts datasource credentials in its DB with this. NixOS 26.05
  # dropped the built-in default, so it has to be supplied; $__file{} keeps it
  # out of the world-readable store copy of grafana.ini.
  sops.secrets.grafana_secret_key = {
    sopsFile = ../../secrets/grafana.enc.json;
    format = "json";
    key = "secret_key";
    owner = "grafana";
    mode = "0400";
  };

  services = {
    grafana = {
      enable = true;

      settings = {
        server = {
          http_addr = "0.0.0.0";
          http_port = grafanaPort;
        };

        security.secret_key = "$__file{${config.sops.secrets.grafana_secret_key.path}}";
      };

      # Datasources are provisioned rather than clicked in, so a rebuild is
      # enough to get a working Grafana on a fresh machine.
      provision.datasources.settings = {
        apiVersion = 1;
        datasources = [
          {
            name = "Prometheus";
            uid = "prometheus";
            type = "prometheus";
            url = "http://127.0.0.1:${toString prometheusPort}";
            isDefault = true;
          }
          {
            name = "Loki";
            uid = "loki";
            type = "loki";
            url = "http://127.0.0.1:${toString lokiPort}";
          }
          {
            name = "Tempo";
            uid = "tempo";
            type = "tempo";
            url = "http://127.0.0.1:${toString tempoPort}";
          }
        ];
      };
    };

    prometheus = {
      enable = true;
      port = prometheusPort;
      listenAddress = "0.0.0.0";
      globalConfig.scrape_interval = "15s";

      # Only scrapes itself for now. Docker services that expose /metrics get
      # added here as further jobs, pointing at the port they publish on the
      # host.
      scrapeConfigs = [
        {
          job_name = "prometheus";
          static_configs = [ { targets = [ "127.0.0.1:${toString prometheusPort}" ]; } ];
        }
      ];
    };

    loki = {
      enable = true;
      dataDir = lokiDir;

      configuration = {
        # Single tenant: nothing here sends an X-Scope-OrgID header.
        auth_enabled = false;

        server = {
          http_listen_address = "0.0.0.0";
          http_listen_port = lokiPort;
          grpc_listen_address = "127.0.0.1";
          grpc_listen_port = lokiGrpcPort;
        };

        common = {
          instance_addr = "127.0.0.1";
          path_prefix = lokiDir;
          replication_factor = 1;
          ring.kvstore.store = "inmemory";
          storage.filesystem = {
            chunks_directory = "${lokiDir}/chunks";
            rules_directory = "${lokiDir}/rules";
          };
        };

        # tsdb + v13 is what Loki 3.x wants; the older boltdb-shipper/v11 combo
        # is accepted but deprecated.
        schema_config.configs = [
          {
            from = "2026-01-01";
            store = "tsdb";
            object_store = "filesystem";
            schema = "v13";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }
        ];
      };
    };

    tempo = {
      enable = true;

      settings = {
        server = {
          http_listen_address = "0.0.0.0";
          http_listen_port = tempoPort;
        };

        # The OTLP endpoints Docker services point OTEL_EXPORTER_OTLP_ENDPOINT at.
        distributor.receivers.otlp.protocols = {
          grpc.endpoint = "0.0.0.0:${toString otlpGrpcPort}";
          http.endpoint = "0.0.0.0:${toString otlpHttpPort}";
        };

        # The unit runs with DynamicUser, which implies ProtectSystem=strict, so
        # StateDirectory=tempo is the only writable path. Every path below
        # otherwise defaults somewhere under /var/tempo and Tempo crash-loops on
        # "mkdir /var/tempo: read-only file system".
        storage.trace = {
          backend = "local";
          local.path = "${tempoDir}/traces";
          wal.path = "${tempoDir}/wal";
        };

        live_store = {
          wal.path = "${tempoDir}/live-store/traces";
          shutdown_marker_dir = "${tempoDir}/live-store/shutdown-marker";
        };

        block_builder.wal.path = "${tempoDir}/block-builder/traces";
        backend_scheduler.local_work_path = "${tempoDir}/scheduler";
      };
    };
  };

  networking.firewall.extraCommands = lib.concatMapStringsSep "\n" restrictPort exposedPorts;
}
