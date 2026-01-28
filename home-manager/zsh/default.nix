{ pkgs, ... }:
{
  home.packages = with pkgs; [ zsh ];

  home.file.".zshrc".source = ./.zshrc;
  home.file.".p10k.zsh".source = ./.p10k.zsh;
  home.file.".config/zsh/kubectl.zsh".source = ./kubectl.zsh;
}
