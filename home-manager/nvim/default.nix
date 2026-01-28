{ pkgs, ... }:
{

  home.packages = with pkgs; [
    neovim
    # Required for lazy.nvim to work
    git
  ];

  xdg.configFile = {
    "nvim/init.lua".source = ./init.lua;
    "nvim/stylua.toml".source = ./stylua.toml;
    "nvim/lua/config".source = ./lua/config;
    "nvim/lua/misc".source = ./lua/misc;
    "nvim/lua/plugins".source = ./lua/plugins;
  };

}
