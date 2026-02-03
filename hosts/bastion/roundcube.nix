{ config, pkgs, ... }:

let
  domain = "hgeorgiev.com";
  roundcubeHostname = "webmail.${domain}";
  mailHostname = "mail.${domain}";
in
{
  services.roundcube = {
    enable = true;
    hostName = roundcubeHostname;

    # Use the same ACME certificate as nginx will generate
    # Roundcube will be served through nginx
    package = pkgs.roundcube.withPlugins (plugins: [
      plugins.persistent_login
      plugins.carddav
    ]);

    # Database configuration - use PostgreSQL (required by NixOS module)
    database = {
      dbname = "roundcube";
      host = "localhost";
      username = "roundcube";
      passwordFile = "/var/lib/roundcube/db_password";
    };

    # IMAP/SMTP configuration - connect to local mail server
    extraConfig = ''
      # IMAP settings - connect to local Dovecot
      $config['imap_host'] = 'ssl://${mailHostname}:993';
      $config['imap_auth_type'] = 'LOGIN';
      $config['imap_conn_options'] = array(
        'ssl' => array(
          'verify_peer' => true,
          'verify_peer_name' => true,
        ),
      );

      # SMTP settings - connect to local Postfix submission port
      $config['smtp_host'] = 'tls://${mailHostname}:587';
      $config['smtp_auth_type'] = 'LOGIN';
      $config['smtp_conn_options'] = array(
        'ssl' => array(
          'verify_peer' => true,
          'verify_peer_name' => true,
        ),
      );

      # Default settings
      $config['product_name'] = 'Webmail';
      $config['support_url'] = "";
      $config['des_key'] = file_get_contents('/var/lib/roundcube/des_key');

      # User interface settings
      $config['language'] = 'en_US';
      $config['date_format'] = 'Y-m-d';
      $config['time_format'] = 'H:i';
      $config['draft_autosave'] = 60;
      $config['preview_pane'] = true;

      # Security settings
      $config['login_autocomplete'] = 2;
      $config['ip_check'] = true;
      $config['session_lifetime'] = 60;

      # Plugins
      $config['plugins'] = array('persistent_login', 'carddav');

      # Default identity
      $config['identities_level'] = 0;

      # Addressbook settings
      $config['autocomplete_addressbooks'] = array('sql');
    '';
  };

  # Enable PostgreSQL for Roundcube
  services.postgresql = {
    enable = true;
    ensureDatabases = [ "roundcube" ];
    ensureUsers = [
      {
        name = "roundcube";
        ensureDBOwnership = true;
      }
    ];
  };

  # Generate random secrets for Roundcube
  systemd.services.roundcube-secrets = {
    description = "Generate Roundcube secrets";
    wantedBy = [ "multi-user.target" ];
    before = [ "phpfpm-roundcube.service" ];
    after = [
      "postgresql.service"
      "postgresql-ensure-users.service"
    ];
    requires = [ "postgresql.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      mkdir -p /var/lib/roundcube

      # Generate DES key if not exists
      if [ ! -f /var/lib/roundcube/des_key ]; then
        ${pkgs.openssl}/bin/openssl rand -base64 24 > /var/lib/roundcube/des_key
        chmod 600 /var/lib/roundcube/des_key
        chown roundcube:roundcube /var/lib/roundcube/des_key
      fi

      # Generate DB password if not exists
      if [ ! -f /var/lib/roundcube/db_password ]; then
        ${pkgs.openssl}/bin/openssl rand -base64 32 | tr -d '\n' > /var/lib/roundcube/db_password
        chmod 600 /var/lib/roundcube/db_password
        chown roundcube:roundcube /var/lib/roundcube/db_password
      fi

      # Always ensure the password is set in PostgreSQL (in case DB was recreated)
      if [ -f /var/lib/roundcube/db_password ]; then
        PASSWORD=$(cat /var/lib/roundcube/db_password)
        ${pkgs.sudo}/bin/sudo -u postgres ${pkgs.postgresql}/bin/psql -c "ALTER USER roundcube WITH PASSWORD '$PASSWORD';" || true
      fi
    '';
  };

  # Ensure roundcube directory exists
  systemd.tmpfiles.rules = [
    "d /var/lib/roundcube 0750 roundcube roundcube -"
  ];
}
