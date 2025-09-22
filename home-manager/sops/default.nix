{ pkgs, ... }: {
  home.packages = with pkgs; [ sops ];

  home.file.".sops.yaml".source = ./.sops.yaml;
}
