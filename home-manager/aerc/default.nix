# aerc, reading mail from mail.hgeorgiev.com.
#
# Passwords come from secrets/mailboxes.enc.json via sops-nix (see ../sops),
# which decrypts them to 0400 files under ~/.config/aerc. aerc reads those with
# source-cred-cmd / outgoing-cred-cmd rather than having them inlined, so
# accounts.conf itself holds no credentials - which matters, because
# home-manager writes it into the world-readable Nix store.
{ config, ... }:
let
  imapHost = "mail.hgeorgiev.com:993";
  smtpHost = "mail.hgeorgiev.com:465";

  # dovecot runs with ssl=required and postfix exposes submissions on 465 with
  # implicit TLS, so both ends are imaps/smtps rather than STARTTLS on 587.
  # The username is the full address, so its @ has to be percent-encoded:
  # aerc parses these with Go's net/url, whose validUserinfo rejects a bare @
  # in the userinfo with "invalid userinfo".
  account =
    address: passwordFile:
    let
      user = builtins.replaceStrings [ "@" ] [ "%40" ] address;
    in
    {
      from = address;
      source = "imaps://${user}@${imapHost}";
      source-cred-cmd = "cat ${passwordFile}";
      outgoing = "smtps://${user}@${smtpHost}";
      outgoing-cred-cmd = "cat ${passwordFile}";
      default = "INBOX";
      # dovecot's inbox namespace has no prefix and separator "/", with a
      # Sent mailbox flagged \\Sent - so this is the plain name.
      copy-to = "Sent";
      cache-headers = true;
    };
in
{
  imports = [ ../sops ];

  programs.aerc = {
    enable = true;

    extraAccounts = {
      "me@hgeorgiev.com" = account "me@hgeorgiev.com" config.sops.secrets.mail_me_hgeorgiev.path;
      "contacts@dissona.app" =
        account "contacts@dissona.app" config.sops.secrets.mail_contacts_dissona.path;
      # Named no-reply but it is a real mailbox with its own Maildir, so
      # bounces and people who reply anyway are readable rather than lost.
      "no-reply@dissona.app" =
        account "no-reply@dissona.app" config.sops.secrets.mail_no_reply_dissona.path;
    };

    extraConfig = {
      # aerc refuses to start if accounts.conf is group- or world-readable,
      # which a Nix store path always is. The check exists to stop passwords
      # leaking from that file; ours holds none - only cred-cmds pointing at
      # the 0400 files sops writes - so the check is the wrong one here.
      general.unsafe-accounts-conf = true;

      ui = {
        threading-enabled = true;
        sort = "-r date";
      };

      viewer.alternatives = "text/plain,text/html";

      compose.editor = "nvim";

      # Setting anything here makes home-manager write the whole aerc.conf,
      # and aerc does not merge the packaged defaults underneath it - so the
      # stock [filters] have to be repeated or there is nothing to render a
      # part with. Without them aerc falls through to :open, which hands the
      # mail to xdg-open and lands it in a browser. These are the aerc 0.22
      # defaults; the filter scripts ship in the aerc package's libexec and
      # aerc puts that directory on $PATH itself.
      filters = {
        "text/plain" = "colorize";
        "text/calendar" = "calendar";
        "message/delivery-status" = "colorize";
        "message/rfc822" = "colorize";
        "text/html" = "! html";
        ".headers" = "colorize";
      };
    };
  };
}
