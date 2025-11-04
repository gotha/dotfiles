{ pkgs, ... }:
with pkgs;
let
  gcloud = pkgs.google-cloud-sdk.withExtraComponents
    [ pkgs.google-cloud-sdk.components.gke-gcloud-auth-plugin ];
in [
  _1password-cli
  awscli2
  bc
  bison
  clang
  clang-tools
  cloc
  direnv
  eslint
  gcloud
  git-lfs
  go
  gofumpt
  gopls
  gnumake
  gnupg
  less
  lua
  ncdu
  neovim
  nil
  nixfmt-classic
  nix-search-cli
  nodejs
  nodePackages_latest.prettier
  pyright
  python314
  ripgrep
  shfmt
  sops
  stow
  stylua
  tmux
  tree
  typescript
  typescript-language-server
  unzip
  vale
  watch
]
