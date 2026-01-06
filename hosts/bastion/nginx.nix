{ config, pkgs, ... }:

{
  # Configure nginx reverse proxy
  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;

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
  };

  # Configure ACME for Let's Encrypt SSL certificates
  security.acme = {
    acceptTerms = true;
    defaults.email = "h.georgiev@hotmail.com";
  };

  # Open firewall ports for HTTP and HTTPS
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
