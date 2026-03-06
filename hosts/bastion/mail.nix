{ config, pkgs, ... }:

let
  domain = "hgeorgiev.com";
  mailHostname = "mail.${domain}";
  certDir = config.security.acme.certs.${mailHostname}.directory;
in
{
  # ============================================================================
  # SOPS Secrets for DKIM
  # ============================================================================
  sops.secrets.dkim_private_key = {
    sopsFile = ../../secrets/dkim-key.enc;
    format = "binary";
    owner = "rspamd";
    group = "rspamd";
    mode = "0400";
    path = "/var/lib/rspamd/dkim/${domain}.mail.key";
  };

  # ============================================================================
  # Virtual Mail User
  # ============================================================================
  users.users.vmail = {
    isSystemUser = true;
    uid = 5000;
    group = "vmail";
    home = "/var/vmail";
    createHome = true;
    description = "Virtual mail user";
  };

  users.groups.vmail = {
    gid = 5000;
  };

  # ============================================================================
  # Rspamd - DKIM Signing & Spam Filtering
  # ============================================================================
  services.rspamd = {
    enable = true;
    locals = {
      "dkim_signing.conf" = {
        text = ''
          enabled = true;
          sign_authenticated = true;
          sign_local = true;
          use_domain = "header";
          use_redis = false;
          use_esld = false;
          allow_hdrfrom_mismatch = false;
          allow_hdrfrom_mismatch_sign_networks = false;
          allow_username_mismatch = false;
          sign_networks = "/^(127\\.0\\.0\\.1|::1)$/";
          selector = "mail";
          path = "/var/lib/rspamd/dkim/$domain.$selector.key";
          domain {
            ${domain} {
              selector = "mail";
              path = "/var/lib/rspamd/dkim/${domain}.mail.key";
            }
          }
        '';
      };
      "worker-proxy.inc" = {
        text = ''
          milter = yes;
          timeout = 120s;
          upstream "local" {
            default = yes;
            self_scan = yes;
          }
          count = 4;
          max_retries = 5;
          discard_on_reject = false;
          quarantine_on_reject = false;
          spam_header = "X-Spam";
          reject_message = "This message is likely spam";
        '';
      };
      "worker-controller.inc" = {
        text = ''
          password = "$2$abc123abc123abc123abc123abc123ab$abc123abc123abc123abc123abc123abc123abc123abc123";
          enable_password = "$2$abc123abc123abc123abc123abc123ab$abc123abc123abc123abc123abc123abc123abc123abc123";
          secure_ip = "127.0.0.1";
          secure_ip = "::1";
        '';
      };
      # Disable modules we don't need for basic DKIM signing
      "classifier-bayes.conf" = {
        text = ''
          enabled = false;
        '';
      };
    };
  };

  # Ensure rspamd directory structure exists
  systemd.tmpfiles.rules = [
    "d /var/lib/rspamd/dkim 0750 rspamd rspamd -"
    # Virtual mail directories
    "d /var/vmail 0750 vmail vmail -"
    "d /var/vmail/${domain} 0750 vmail vmail -"
    "d /var/vmail/${domain}/me 0750 vmail vmail -"
    "d /var/vmail/${domain}/me/Maildir 0750 vmail vmail -"
    "d /var/vmail/${domain}/me/Maildir/new 0750 vmail vmail -"
    "d /var/vmail/${domain}/me/Maildir/cur 0750 vmail vmail -"
    "d /var/vmail/${domain}/me/Maildir/tmp 0750 vmail vmail -"
  ];

  # ============================================================================
  # Postfix - SMTP Server
  # ============================================================================
  services.postfix = {
    enable = true;

    settings.main = {
      # Basic settings
      myhostname = mailHostname;
      mydomain = domain;
      myorigin = domain;
      # Note: domain is NOT in mydestination because it's in virtual_mailbox_domains
      mydestination = [
        "localhost"
        mailHostname
      ];
      inet_interfaces = "all";
      inet_protocols = "ipv4";
      mynetworks_style = "host";

      # TLS settings for incoming connections (server)
      smtpd_tls_chain_files = [
        "${certDir}/key.pem"
        "${certDir}/fullchain.pem"
      ];
      smtpd_tls_security_level = "may";
      smtpd_tls_auth_only = "yes";
      smtpd_tls_loglevel = 1;
      smtpd_tls_received_header = "yes";
      smtpd_tls_protocols = "!SSLv2, !SSLv3, !TLSv1, !TLSv1.1";

      # TLS settings for outgoing connections (client)
      smtp_tls_security_level = "may";
      smtp_tls_loglevel = 1;
      smtp_tls_protocols = "!SSLv2, !SSLv3, !TLSv1, !TLSv1.1";

      # SASL Authentication (via Dovecot)
      smtpd_sasl_type = "dovecot";
      smtpd_sasl_path = "private/auth";
      smtpd_sasl_auth_enable = "yes";
      smtpd_sasl_security_options = "noanonymous";
      smtpd_sasl_local_domain = "$myhostname";

      # Recipient restrictions
      smtpd_recipient_restrictions = "permit_sasl_authenticated, permit_mynetworks, reject_unauth_destination, reject_invalid_hostname, reject_non_fqdn_hostname, reject_non_fqdn_sender, reject_non_fqdn_recipient, reject_unknown_sender_domain, reject_unknown_recipient_domain";

      # HELO restrictions
      smtpd_helo_required = "yes";
      smtpd_helo_restrictions = "permit_mynetworks, permit_sasl_authenticated, reject_invalid_helo_hostname, reject_non_fqdn_helo_hostname";

      # Milter configuration for rspamd (DKIM signing)
      milter_default_action = "accept";
      milter_protocol = "6";
      smtpd_milters = "unix:/run/rspamd/rspamd-milter.sock";
      non_smtpd_milters = "unix:/run/rspamd/rspamd-milter.sock";

      # Virtual mailbox configuration
      virtual_mailbox_domains = domain;
      virtual_mailbox_base = "/var/vmail";
      virtual_mailbox_maps = "hash:/var/lib/postfix/conf/vmailbox";
      virtual_alias_maps = "hash:/var/lib/postfix/conf/virtual";
      virtual_uid_maps = "static:5000";
      virtual_gid_maps = "static:5000";

      # Message size limit (25MB)
      message_size_limit = 26214400;
    };

    # Enable submission port (587) for authenticated users
    enableSubmission = true;
    submissionOptions = {
      smtpd_tls_security_level = "encrypt";
      smtpd_sasl_auth_enable = "yes";
      smtpd_sasl_type = "dovecot";
      smtpd_sasl_path = "private/auth";
      smtpd_client_restrictions = "permit_sasl_authenticated,reject";
      milter_macro_daemon_name = "ORIGINATING";
    };

    # Enable submissions port (465) for implicit TLS
    enableSubmissions = true;
    submissionsOptions = {
      smtpd_sasl_auth_enable = "yes";
      smtpd_sasl_type = "dovecot";
      smtpd_sasl_path = "private/auth";
      smtpd_client_restrictions = "permit_sasl_authenticated,reject";
      milter_macro_daemon_name = "ORIGINATING";
    };
  };

  # ============================================================================
  # Dovecot - IMAP Server
  # ============================================================================
  services.dovecot2 = {
    enable = true;
    enableImap = true;
    enablePop3 = false;
    enableLmtp = true;

    mailLocation = "maildir:/var/vmail/%d/%n/Maildir";

    sslServerCert = "${certDir}/fullchain.pem";
    sslServerKey = "${certDir}/key.pem";

    extraConfig = ''
      # SSL/TLS settings
      ssl = required
      ssl_min_protocol = TLSv1.2
      ssl_prefer_server_ciphers = yes

      # Authentication settings
      auth_mechanisms = plain login
      disable_plaintext_auth = yes

      # Mail settings
      mail_privileged_group = vmail
      mail_uid = 5000
      mail_gid = 5000

      # Namespace configuration
      namespace inbox {
        inbox = yes
        separator = /

        mailbox Drafts {
          auto = subscribe
          special_use = \Drafts
        }
        mailbox Sent {
          auto = subscribe
          special_use = \Sent
        }
        mailbox "Sent Messages" {
          special_use = \Sent
        }
        mailbox Trash {
          auto = subscribe
          special_use = \Trash
        }
        mailbox Junk {
          auto = subscribe
          special_use = \Junk
        }
        mailbox Archive {
          auto = subscribe
          special_use = \Archive
        }
      }

      # SASL authentication for Postfix
      service auth {
        unix_listener /var/lib/postfix/queue/private/auth {
          mode = 0660
          user = postfix
          group = postfix
        }
      }

      # LMTP for local delivery
      service lmtp {
        unix_listener /var/lib/postfix/queue/private/dovecot-lmtp {
          mode = 0600
          user = postfix
          group = postfix
        }
      }

      # Password database - using passwd-file for virtual users
      passdb {
        driver = passwd-file
        args = scheme=SHA512-CRYPT /etc/dovecot/users
      }

      # User database
      userdb {
        driver = static
        args = uid=5000 gid=5000 home=/var/vmail/%d/%n
      }

      # Logging
      log_path = syslog
      syslog_facility = mail
      auth_verbose = yes
      auth_verbose_passwords = no
      auth_debug = no
      mail_debug = no
    '';
  };

  # ============================================================================
  # Virtual Mailbox and Alias Configuration Files
  # ============================================================================
  services.postfix.mapFiles = {
    vmailbox = pkgs.writeText "vmailbox" ''
      # Virtual mailboxes - format: email@domain.com    domain.com/user/Maildir/
      # Add your mailboxes here, e.g.:
      postmaster@${domain}    ${domain}/postmaster/Maildir/
      admin@${domain}         ${domain}/admin/Maildir/
      me@${domain}            ${domain}/me/Maildir/
    '';
    virtual = pkgs.writeText "virtual" ''
      # Virtual aliases - format: alias@domain.com    target@domain.com
      # Add your aliases here, e.g.:
      # abuse@${domain}         postmaster@${domain}
      # webmaster@${domain}     postmaster@${domain}
    '';
  };

  # Dovecot users file (virtual users with passwords)
  environment.etc."dovecot/users" = {
    text = ''
      # Virtual users - format: user@domain:{scheme}password
      # Generate password hash with: doveadm pw -s SHA512-CRYPT
      # Example:
      # postmaster@${domain}:{SHA512-CRYPT}$6$...hash...
      me@${domain}:{SHA512-CRYPT}$6$QsFatvmI5WDrohOu$zjSBT0LVYfxRYQPDdappLoxFvtbDOfXvc.xH/Aq./Hr4RHKum6sbZvNYAfsmTU.zoLtCjubcSYJhYw3RCty8k.
    '';
    mode = "0600";
    user = "dovecot2";
    group = "dovecot2";
  };

  # ============================================================================
  # Firewall Configuration
  # ============================================================================
  networking.firewall.allowedTCPPorts = [
    25 # SMTP
    465 # SMTPS (submissions)
    587 # Submission
    993 # IMAPS
  ];

  # ============================================================================
  # Ensure ACME certificate is available for mail services
  # ============================================================================
  security.acme.certs.${mailHostname} = {
    group = "nginx";
    postRun = ''
      systemctl reload postfix || true
      systemctl reload dovecot2 || true
    '';
  };

  # Add postfix and dovecot to the nginx group to read certificates
  # Add postfix to rspamd group to access the milter socket
  users.users.postfix.extraGroups = [
    "nginx"
    "rspamd"
  ];
  users.users.dovecot2.extraGroups = [ "nginx" ];
}
