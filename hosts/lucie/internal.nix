{ lib, ... }:
let
  # Every service below runs on this host, so nginx reaches them over loopback
  # and the map carries no address - only a port.
  #
  # Names resolve two ways, which is the point of splitting them here rather
  # than proxying centrally:
  #
  #   from lucie   /etc/hosts sends them to 127.0.0.1, so a request never
  #                leaves the machine that is serving it
  #   from a peer  dnsmasq on bastion answers with lucie's VPN address and
  #                bastion forwards the packets in the kernel - it routes,
  #                rather than terminating and re-opening every connection
  #
  # Adding a service is an entry here. bastion needs no change: its record is a
  # wildcard over the whole .internal domain.
  #
  # All plain HTTP. Both hops are already WireGuard-encrypted, and .internal is
  # an ICANN-reserved private-use TLD no public CA will issue a certificate for.
  #
  # extraConfig is optional and lands inside the proxy location block.

  # Long-running streamed responses: a model can think for minutes before the
  # first token, and nginx's 60s default proxy_read_timeout would cut that off
  # mid-generation. Buffering off so tokens arrive as they are produced.
  streamingLlm = ''
    proxy_buffering off;
    proxy_read_timeout 600s;
  '';

  internalServices = {
    grafana.port = 32010;
    prometheus.port = 32020;

    # No web UI of their own - Grafana reaches both over localhost anyway.
    # Named so logcli and curl have something to talk to.
    loki.port = 32030;
    tempo.port = 32040;

    transmission = {
      port = 9091;
      # Adding a torrent uploads a .torrent file.
      extraConfig = ''
        client_max_body_size 100M;
      '';
    };

    ollama = {
      port = 11434;
      extraConfig = streamingLlm;
    };
    litellm = {
      port = 14000;
      extraConfig = streamingLlm;
    };

    # nix-serve, matching the cachix name it already answers to publicly.
    cachix.port = 5000;
  };

  internalNames = map (name: "${name}.internal") (builtins.attrNames internalServices);
in
{
  # nsswitch consults files before dns, so these win over whatever bastion
  # would answer and this host never asks. Without it lucie would resolve its
  # own services to 10.100.0.100 and reach them by way of a droplet in another
  # country.
  networking.hosts."127.0.0.1" = internalNames;

  services.nginx.virtualHosts =
    lib.mapAttrs' (
      name: svc:
      lib.nameValuePair "${name}.internal" {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString svc.port}";
          # Grafana's live tailing and Transmission's UI use websockets.
          proxyWebsockets = true;
          recommendedProxySettings = true;
          extraConfig = svc.extraConfig or "";
        };
      }
    ) internalServices
    // {
      # Deliberately not bound to 10.100.0.100: bastion proxies the public
      # nextcloud.hgeorgiev.com to http://10.100.0.100, and a listener specific
      # to that address would take those requests, fail to match a server_name
      # and hand them to the catch-all below. Listening on every address costs
      # nothing here - each of these services already admits 192.168.0.0/16 on
      # its own port, via openFirewall or an explicit rule.
      #
      # bastion's wildcard resolves typos as readily as real names, so without a
      # default server a misspelling would be answered by whichever vhost nginx
      # picked first. Fail visibly instead.
      "internal-catchall" = {
        default = true;
        locations."/".return = "404";
      };

      # Reaching Nextcloud by IP is in its trusted_domains and worked only
      # because it was the sole vhost here, and so the accidental default. The
      # catch-all above takes that role, so the alias makes it deliberate.
      "nextcloud.hgeorgiev.com".serverAliases = [ "10.100.0.100" ];
    };
}
