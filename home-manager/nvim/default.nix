{ pkgs, ... }:
{
  # Tools that already have their own home-manager modules are pulled in here
  # so importing nvim is enough to get its plugin dependencies.
  imports = [
    ../nodejs
    ../vale
  ];

  home.packages = with pkgs; [
    neovim
    # Required for lazy.nvim to clone plugins.
    git
    lazygit

    # Formatters used by conform.nvim (lua/plugins/conform.lua).
    rustfmt
    djlint
    ktlint
    phpPackages.php-cs-fixer
    # stylua, gofumpt, ruff, nixfmt and clang-tools are still sourced from
    # config/packages-user.nix until per-language modules exist.

    # LSPs configured in lua/plugins/nvim-lspconfig.lua.
    rust-analyzer
    phpactor
    terraform-ls
    regols
    gopls
    ruff
    pyright
    nixd
  ];

  xdg.configFile = {
    "nvim/init.lua".source = ./init.lua;
    "nvim/stylua.toml".source = ./stylua.toml;
    "nvim/lua/config".source = ./lua/config;
    "nvim/lua/misc".source = ./lua/misc;
    "nvim/lua/plugins".source = ./lua/plugins;
  };
}
