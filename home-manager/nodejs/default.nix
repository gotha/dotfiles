# Node.js ecosystem: runtime, package manager config, and common JS/TS tooling.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nodejs
    prettier
    eslint
    typescript
    typescript-language-server
  ];

  home.file.".npmrc".source = ./npmrc;
}
