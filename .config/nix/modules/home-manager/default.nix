{ pkgs, ... }: {
  home.stateVersion = "24.05";
  home.packages = with pkgs; [
    awscli
    bison
    caddy
    checkstyle
    cloc
    clang
    clang-tools
    curl
    ffmpeg
    git
    go
    gofumpt
    gopls
    gnumake
    htop
    httpie
    jq
    less
    lua
    ncdu
    neovim
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
    stow
    stylua
    tcptraceroute
    tmux
    vale
    vault
    volta
    watch
    wget
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
  programs.eza.enable = true;
  programs.git.enable = true;
  programs.starship.enable = true;
  programs.starship.enableZshIntegration = true;
  programs.alacritty = {
    enable = true;
    settings.font.normal.family = "MesloLGS Nerd Font Mono";
    settings.font.size = 16;
  };
}
