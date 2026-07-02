{ pkgs, ... }:
let
  # On Darwin every compiler routes through the nix cc-wrapper, which drops the
  # libSystem link inputs whenever `--target` is present (undefined _calloc,
  # __DefaultRuneLocale, ... at link time). The tree-sitter CLI always passes
  # `--target=arm64-apple-macosx`. This shim strips that flag and forwards to the
  # real compiler, so the wrapper falls back to its correct native
  # arm64-apple-darwin target and links libSystem normally. Pointed at via
  # $CC/$CXX in lua/plugins/treesitter.lua (Darwin only).
  mkTsCompiler =
    name: underlying:
    pkgs.writeShellScriptBin name ''
      args=()
      skip=0
      for a in "$@"; do
        if [ "$skip" = 1 ]; then
          skip=0
          continue
        fi
        case "$a" in
          --target=* | -target=*) ;;
          --target | -target) skip=1 ;;
          *) args+=("$a") ;;
        esac
      done
      exec ${pkgs.stdenv.cc}/bin/${underlying} "''${args[@]}"
    '';
  nvimTsCc = mkTsCompiler "nvim-ts-cc" "cc";
  nvimTsCxx = mkTsCompiler "nvim-ts-cxx" "c++";
in
{
  # Tools that already have their own home-manager modules are pulled in here
  # so importing nvim is enough to get its plugin dependencies.
  imports = [
    ../nodejs
    ../vale
  ];

  home.packages =
    with pkgs;
    [
      neovim
      # Required for lazy.nvim to clone plugins.
      git
      lazygit
      # nvim-treesitter (main branch) builds parsers via the tree-sitter CLI and a
      # C compiler, fetching parser sources with curl (tar comes from coreutils).
      tree-sitter
      curl

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

      ripgrep # needed for telescope
    ]
    # C compiler for tree-sitter parser builds. On Darwin use the --target-
    # stripping shims above (the wrapped clang otherwise fails to link); on Linux
    # gcc is the correct default and needs no shim.
    ++ lib.optionals stdenv.isDarwin [
      nvimTsCc
      nvimTsCxx
    ]
    ++ lib.optional stdenv.isLinux gcc;

  xdg.configFile = {
    "nvim/init.lua".source = ./init.lua;
    "nvim/stylua.toml".source = ./stylua.toml;
    "nvim/lua/config".source = ./lua/config;
    "nvim/lua/misc".source = ./lua/misc;
    "nvim/lua/plugins".source = ./lua/plugins;
  };
}
