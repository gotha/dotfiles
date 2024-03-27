{ pkgs, ... }: {
  fonts.fontconfig.enable = true;
  home.stateVersion = "24.05";
  home.packages = with pkgs; [
    awscli2
    caddy
    checkstyle
    docker
    ffmpeg
    httpie
    lua
    ncdu
    neofetch
    neovim
    ( nerdfonts.override { fonts = [ "FiraCode" ]; })
    nodejs
    pandoc
    (php.buildEnv {
      extensions = ({ enabled, all }: enabled ++ (with all; [
        xdebug
      ]));
      extraConfig = ''
	xdebug.mode=debug
      '';
    })
    php.packages.composer
    php.packages.phpstan
    php.packages.php-cs-fixer
    phpactor
    postgis
    pyright
    python3
    qemu
    ripgrep
    rustup
    shfmt
    stylua
    symfony-cli
    tcptraceroute
    vale
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
