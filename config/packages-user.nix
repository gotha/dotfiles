{ pkgs, stablePkgs, ... }:
with pkgs;
let
  # Use stable version of gcloud to avoid Tkinter issues in latest unstable
  gcloud = stablePkgs.google-cloud-sdk.withExtraComponents [
    stablePkgs.google-cloud-sdk.components.gke-gcloud-auth-plugin
  ];
in
[
  _1password-cli
  awscli2
  bc
  bison
  clang
  clang-tools
  cloc
  direnv
  entire
  gcloud
  gh
  go
  gofumpt
  gopls
  gnumake
  heroku
  hunk
  kubectl
  less
  lua
  ncdu
  nixd
  nixfmt
  nix-search-cli
  pyright
  python314
  ripgrep
  ruff
  shfmt
  llm-agents.spec-kit
  llm-agents.skills
  stow
  stylua
  tree
  unzip
  uv
  watch
  yt-dlp
]
