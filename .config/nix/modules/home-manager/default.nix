{ pkgs, ... }: {
  home.stateVersion = "24.05";
  home.packages = with pkgs; [
    awscli
    caddy
    checkstyle
    cloc
    curl
    ffmpeg
    git
    gofumpt
    htop
    httpie
    jq
    less
    lua
    neovim
    pandoc
    php
    postgis
    pyright
    qemu
    ripgrep
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
  programs.zsh.enable = true;
  programs.zsh.enableCompletion = true;
  programs.zsh.enableAutosuggestions = true;
  programs.zsh.syntaxHighlighting.enable = true;
  programs.zsh.shellAliases = {
    ls = "ls --color=auto -F";
  };
  programs.starship.enable = true;
  programs.starship.enableZshIntegration = true;
  programs.alacritty = {
    enable = true;
    settings.font.normal.family = "MesloLGS Nerd Font Mono";
    settings.font.size = 16;
  };
}