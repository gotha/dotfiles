{ config, pkgs, ... }:

{
  # Configure nginx reverse proxy
  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;

    # Mail server - just for ACME certificate generation
    virtualHosts."mail.hgeorgiev.com" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        return = "200 'Mail server - use IMAP/SMTP clients'";
        extraConfig = ''
          add_header Content-Type text/plain;
        '';
      };
    };

    # Roundcube webmail - SSL configuration
    # The Roundcube module creates the virtual host, we just add SSL
    virtualHosts."webmail.hgeorgiev.com" = {
      forceSSL = true;
      enableACME = true;
    };

    virtualHosts."nextcloud.hgeorgiev.com" = {
      forceSSL = true;
      enableACME = true;

      locations."/" = {
        proxyPass = "http://10.100.0.100";
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_set_header X-Forwarded-Host $host;
          proxy_set_header X-Forwarded-Port $server_port;

          client_max_body_size 10G;
          proxy_buffering off;
        '';
      };
    };

    virtualHosts."dissona.hgeorgiev.com" = {
      forceSSL = true;
      enableACME = true;

      locations."/" = {
        proxyPass = "http://10.100.0.100:7679";
        extraConfig = ''
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto https;
          proxy_set_header X-Forwarded-Host $host;
          proxy_set_header X-Forwarded-Port 443;

          # WebSocket support
          proxy_http_version 1.1;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection "upgrade";

          # Allow large file uploads
          client_max_body_size 1000M;

          # Enable byte-range requests for media streaming
          proxy_set_header Range $http_range;
          proxy_set_header If-Range $http_if_range;
          proxy_force_ranges on;

          # Disable buffering for streaming
          proxy_buffering off;
        '';
      };
    };
  };

  # Configure ACME for Let's Encrypt SSL certificates
  security.acme = {
    acceptTerms = true;
    defaults.email = "h.georgiev@hotmail.com";
  };

  # Open firewall ports for HTTP and HTTPS
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
