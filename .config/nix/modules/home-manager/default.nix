{ pkgs, ... }: {
  fonts.fontconfig.enable = true;
  home.stateVersion = "24.05";
  home.packages = with pkgs; [
    awscli2
    caddy
    checkstyle
    clang
    clang-tools
    docker
    ffmpeg
    go
    gofumpt
    gopls
    httpie
    lua
    ncdu
    neofetch
    neovim
    ( nerdfonts.override { fonts = [ "FiraCode" ]; })
    nodejs
    pandoc
    php
    postgis
    pyright
    python3
    qemu
    ripgrep
    rustup
    shfmt
    stylua
    tcptraceroute
    vale
    vault
    volta
    watch
  ];
  home.sessionVariables = {
    PAGER = "less";
    CLICLOLOR = 1;
    EDITOR = "nvim";
  };
  programs.bat.enable = true;
  programs.bat.config.theme = "TwoDark";
  programs.fzf.enable = true;
  programs.fzf.enableZshIntegration = true;
}
