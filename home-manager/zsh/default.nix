{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [ zsh ];

    file = {
      ".zshrc".source = ./.zshrc;
      ".p10k.zsh".source = ./.p10k.zsh;
      ".config/zsh/kubectl.zsh".source = ./kubectl.zsh;
    };
  };
}
