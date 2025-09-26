{ pkgs, lib, ... }:
let
  marketplaceExts = pkgs.vscode-utils.extensionsFromVscodeMarketplace [{
    name = "vscode-augment";
    publisher = "augment";
    version = "0.568.0";
    sha256 = "sha256-rUFtZCu2y89XAA2B/i9Wn2a2lFEA77UxE5KlUj0VZPE=";
  }];
in {

  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;

    # Lock extensions to what we declare here
    mutableExtensionsDir = true;
    profiles = {
      default = {
        userSettings = {
          # Disable all telemetry
          "telemetry.telemetryLevel" = "off";
          "telemetry.enableCrashReporter" = false;
          "telemetry.enableTelemetry" = false;

          # Disable data collection
          "workbench.enableExperiments" = false;
          "workbench.settings.enableNaturalLanguageSearch" = false;

          "editor.formatOnSave" = true;
          "workbench.colorTheme" = "Solarized Dark";
          "workbench.activityBar.visible" = false;

          "extensions.autoUpdate" = false;

          # Disable git
          "git.enabled" = true;
          #"git.path" = null;
          #"git.autofetch" = false;

          "github.copilot.enable" = { "*" = false; };
          "github.copilot.chat.enabled" = false;
          "github.copilot.advanced" = {
            "showCopilotStatusInStatusBar" = false;
          };

          "nerdtree.hideSidebarWhenOpenFile" = true;
          "nerdtree.alwaysShowSidebar" = false;

          "editor.cursorBlinking" = "solid";

          #Vim config
          "vim.easymotion" = true;
          "vim.incsearch" = true;
          "vim.useSystemClipboard" = true;
          "vim.useCtrlKeys" = true;
          "vim.hlsearch" = true;

          # Set leader key to space
          "vim.leader" = "<space>";

          # Configure key mappings for normal mode
          "vim.normalModeKeyBindingsNonRecursive" = [
            {
              "before" = [ "<leader>" "a" ];
              "commands" = [ "workbench.action.previousEditor" ];
            }
            {
              "before" = [ "<leader>" "f" ];
              "commands" = [ "workbench.action.nextEditor" ];
            }
            {
              "before" = [ "<leader>" "e" ];
              "commands" = [ "workbench.view.explorer" ];
            }
          ];

          # Augment-specific settings
          "augment.panel.location" = "bottom";
          "augment.chat.panelPosition" = "bottom";

          # General panel settings
          "workbench.panel.defaultLocation" = "bottom";
          "workbench.panel.opensMaximized" = "never";

          # If Augment uses a custom view
          "workbench.view.extension.augment-chat" = "bottom";
        };

        keybindings = [
          # Map capslock to escape because vscodium does not behave under wayland
          {
            key = "capslock";
            command = "extension.vim_escape";
            when = "editorTextFocus && vim.active && !inDebugRepl";
          }
          {
            key = "capslock";
            command = "workbench.action.closeActiveEditor";
            when = "!editorTextFocus";
          }
          {
            key = "ctrl+shift+a";
            command = "augment.openChat";
          }
          {
            key = "ctrl+alt+a";
            command = "augment.togglePanel";
          }
        ];

        extensions = (with pkgs.vscode-extensions; [
          golang.go
          github.vscode-github-actions
          dracula-theme.theme-dracula
          jnoortheen.nix-ide
          vscodevim.vim
          #llam4u.nerdtree
        ]) ++ marketplaceExts;
      };
    };

  };
}
