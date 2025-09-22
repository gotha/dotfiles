{ pkgs, ... }: {
  home.packages = with pkgs; [ tmux git ];

  home.file.".tmux.conf".source = ./tmux.conf;
}
