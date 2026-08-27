{
  config,
  inputs,
  pkgs,
  ...
}:
{

  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  home.packages = with pkgs; [
    sops
    gnupg
  ];

  home.file.".sops.yaml".source = ./.sops.yaml;

  sops = {
    # Use the default GPG home directory
    gnupg.home = "${config.home.homeDirectory}/.gnupg";

    secrets = {
      ".env" = {
        sopsFile = ../../secrets/.env.enc;
        format = "dotenv";
        path = "${config.home.homeDirectory}/.env";
        mode = "0600";
      };

      "mcp_server_github_pac" = {
        sopsFile = ../../secrets/github.env.enc;
        format = "dotenv";
        key = "GITHUB_PERSONAL_ACCESS_TOKEN_MCP_SERVER";
      };

      "mcp_server_circleci_token" = {
        sopsFile = ../../secrets/circleci.env.enc;
        format = "dotenv";
        key = "CIRCLECI_TOKEN";
      };

      "nextcloud_username" = {
        sopsFile = ../../secrets/nextcloud-credentials-lucie-sync.enc.json;
        format = "json";
        key = "username";
      };

      "nextcloud_password" = {
        sopsFile = ../../secrets/nextcloud-credentials-lucie-sync.enc.json;
        format = "json";
        key = "password";
      };

      # aerc reads these with source-cred-cmd / outgoing-cred-cmd, so the
      # passwords never land in accounts.conf. All three are real dovecot
      # users with their own Maildir - see the vmailbox in hosts/bastion/
      # mail.nix - so no-reply gets a full account like the others.
      "mail_me_hgeorgiev" = {
        sopsFile = ../../secrets/mailboxes.enc.json;
        format = "json";
        key = "me@hgeorgiev.com";
        path = "${config.home.homeDirectory}/.config/aerc/me-hgeorgiev.password";
        mode = "0400";
      };

      "mail_contacts_dissona" = {
        sopsFile = ../../secrets/mailboxes.enc.json;
        format = "json";
        key = "contacts@dissona.app";
        path = "${config.home.homeDirectory}/.config/aerc/contacts-dissona.password";
        mode = "0400";
      };

      "mail_no_reply_dissona" = {
        sopsFile = ../../secrets/mailboxes.enc.json;
        format = "json";
        key = "no-reply@dissona.app";
        path = "${config.home.homeDirectory}/.config/aerc/no-reply-dissona.password";
        mode = "0400";
      };

      "crush_openai_key" = {
        sopsFile = ../../secrets/openai.json.enc;
        format = "json";
        key = "CRUSH_API_KEY";
        path = "${config.home.homeDirectory}/.config/crush/openai-api-key";
        mode = "0400";
      };
    };
  };

}
