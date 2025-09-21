{ pkgs, ... }: {
  programs.tmux = {
    enable = true;

    prefix = "C-Space";
    baseIndex = 1;
    mouse = true;
    keyMode = "vi";
    terminal = "screen-256color";

    plugins = with pkgs.tmuxPlugins; [
      #{
      #  plugin = pkgs.tmuxPlugins.mkTmuxPlugin {
      #    pluginName = "tmux-themepack";
      #    version = "unstable-2022-12-20";
      #    src = pkgs.fetchFromGitHub {
      #      owner = "jimeh";
      #      repo = "tmux-themepack";
      #      rev = "7c59902f64dcd7ea356e891274b21144d1ea5948";
      #      sha256 = "1kl93d0b28f4gn1knvbb248xw4vzb0f14hma9kba3blwn830d4bk";
      #    };
      #  };
      #  extraConfig = ''
      #    set -g @themepack 'powerline/default/yellow'
      #  '';
      #}
      { plugin = sensible; }
      { plugin = pain-control; }
      { plugin = vim-tmux-navigator; }
      { plugin = yank; }
      { plugin = copycat; }
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-capture-pane-contents 'on'
          set -g @resurrect-strategy-vim 'session'
          set -g @resurrect-save-shell-history 'on'
        '';
      }
      {
        plugin = sessionist;
        extraConfig = ''
          set -g @sessionist-save-on-exit 'on'
          set -g @sessionist-save-on-destroy 'on'
          set -g @sessionist-save-on-switch 'on'
          set -g @sessionist-save-interval '300'
          # Disable promote-window by binding to unused key combination
          set -g @sessionist-promote-window 'C-123'
        '';
      }
    ];

    extraConfig = ''
      # Send prefix key
      bind C-Space send-prefix

      # Space for last window
      bind Space last-window

      # Mouse binding
      bind -n MouseDown3Pane send-keys -M MouseDown3Pane

      # Empty status right
      set -g status-right ""
    '';
  };
}
