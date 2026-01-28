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

    secrets.".env" = {
      sopsFile = ../../secrets/.env.enc;
      format = "dotenv";
      path = "${config.home.homeDirectory}/.env";
      mode = "0600";
    };

    secrets."mcp_server_github_pac" = {
      sopsFile = ../../secrets/github.env.enc;
      format = "dotenv";
      key = "GITHUB_PERSONAL_ACCESS_TOKEN_MCP_SERVER";
    };
  };

}
