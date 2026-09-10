{
  config,
  pkgs,
  gotha-website,
  gotha-blog,
  ...
}:

{
  # nginx reads this as an htpasswd file. It goes through sops rather than
  # services.nginx.virtualHosts.<name>.basicAuth, which would render the hash
  # into a world-readable file in /nix/store.
  sops.secrets.cachix_htpasswd = {
    sopsFile = ./secrets/cachix.enc.json;
    format = "json";
    key = "htpasswd";
    owner = "nginx";
    group = "nginx";
    mode = "0400";
  };

  # Configure nginx reverse proxy
  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;

    commonHttpConfig = ''
      map $http_upgrade $connection_upgrade {
        default  upgrade;
        ""       "";
      }
    '';

    virtualHosts = {
      # Mail server - just for ACME certificate generation
      "mail.hgeorgiev.com" = {
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
      "webmail.hgeorgiev.com" = {
        forceSSL = true;
        enableACME = true;
      };

      "nextcloud.hgeorgiev.com" = {
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

      # The personal site, and the blog underneath it at /blog. Both are flake
      # inputs whose output is a directory of static files, so there is nothing
      # to run - nginx serves the store paths directly and updating either site
      # is `nix flake update hgg` (or blog) and a redeploy.
      #
      # root for the site, alias for the blog: the URL prefix /blog has to map
      # to the root of the blog package, which is what alias does and root does
      # not. Hugo bakes an absolute baseURL of https://hgeorgiev.com/blog into
      # every link, so the two have to agree - serving it anywhere else means
      # overriding baseURL on the package.
      "hgeorgiev.com" = {
        forceSSL = true;
        enableACME = true;
        serverAliases = [ "www.hgeorgiev.com" ];

        root = "${gotha-website.packages.${pkgs.system}.default}";

        locations = {
          "/" = {
            index = "index.html";
            tryFiles = "$uri $uri/ =404";
          };

          # Bare /blog matches location / rather than the block below, where
          # the site package has no such file, so send it to the slashed form.
          "= /blog".return = "301 /blog/";

          # The trailing slash on the location matters. Without it, alias lets
          # /blog../etc/passwd resolve to <store path>/../etc/passwd - the
          # traversal gixy rejects at build time. A location ending in / can
          # only be entered by a request that also has one.
          #
          # No tryFiles here on purpose: combined with alias it resolves
          # against the wrong base. Hugo writes a directory per page with an
          # index.html inside, so index alone serves them.
          "/blog/" = {
            alias = "${gotha-blog.packages.${pkgs.system}.default}/";
            index = "index.html";
          };
        };
      };

      # Nix binary cache. nix-serve runs on lucie, which has no public address,
      # so bastion terminates TLS and forwards over the tunnel. That is the
      # whole reason this name resolves here rather than to lucie.
      #
      # Kept behind basic auth, as it was on the host this moved from. Store
      # paths are signed either way, so the auth is about not publishing what
      # gets built here rather than about trusting what comes back.
      "cachix.hgeorgiev.com" = {
        forceSSL = true;
        enableACME = true;
        basicAuthFile = config.sops.secrets.cachix_htpasswd.path;

        locations."/" = {
          proxyPass = "http://10.100.0.100:5000";
          recommendedProxySettings = true;
          extraConfig = ''
            # NARs are large and nix streams them; buffering would spool each
            # one onto this droplet's disk before a byte reached the client.
            proxy_buffering off;
          '';
        };
      };

      "dissona.app" = {
        forceSSL = true;
        enableACME = true;
        serverAliases = [ "www.dissona.app" ];

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
            proxy_set_header Connection $connection_upgrade;

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

      # Old domain - redirect to dissona.app
      "dissona.hgeorgiev.com" = {
        forceSSL = true;
        enableACME = true;
        locations."/".return = "301 https://dissona.app$request_uri";
      };

      # Jellyfin, also reachable as jellyfin.internal over the VPN. This is the
      # public route, so Jellyfin's own login is the only thing between the
      # internet and the media library - it wants a strong admin password and
      # prompt updates in a way the internal-only services do not.
      "video.hgeorgiev.com" = {
        forceSSL = true;
        enableACME = true;

        locations."/" = {
          proxyPass = "http://10.100.0.100:8096";
          proxyWebsockets = true;
          recommendedProxySettings = true;
          extraConfig = ''
            # Media streams are large and long-lived; buffering them through
            # this 964 MB droplet would spool them to its disk.
            proxy_buffering off;
            client_max_body_size 0;

            # Seeking in a video is a byte-range request.
            proxy_set_header Range $http_range;
            proxy_set_header If-Range $http_if_range;
            proxy_force_ranges on;
          '';
        };
      };

      "chalgarr.hgeorgiev.com" = {
        forceSSL = true;
        enableACME = true;

        locations."/" = {
          proxyPass = "https://10.100.0.100:11443";
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
            proxy_set_header Connection $connection_upgrade;

            # Allow large file uploads
            client_max_body_size 1000M;

            # Enable byte-range requests for media streaming
            proxy_set_header Range $http_range;
            proxy_set_header If-Range $http_if_range;
            proxy_force_ranges on;

            # Disable buffering for streaming
            proxy_buffering off;

            # SSL backend settings
            proxy_ssl_verify off;
          '';
        };
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
