{ config, inputs, pkgs, ... }: {

  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  home.packages = with pkgs; [ sops gnupg ];

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
  };

}
