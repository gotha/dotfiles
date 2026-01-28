{ pkgs, ... }:
{

  programs.vscode = {
    enable = true;
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
          "workbench.colorTheme" = "Dracula Theme";
          "workbench.activityBar.visible" = false;

          "extensions.autoUpdate" = false;

          # Disable git
          "git.enabled" = false;
          "git.path" = null;
          "git.autofetch" = false;

          "github.copilot.enable" = {
            "*" = false;
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
              "before" = [
                "<leader>"
                "a"
              ];
              "commands" = [ "workbench.action.previousEditor" ];
            }
            {
              "before" = [
                "<leader>"
                "f"
              ];
              "commands" = [ "workbench.action.nextEditor" ];
            }
            {
              "before" = [
                "<leader>"
                "e"
              ];
              "commands" = [ "workbench.view.explorer" ];
            }
          ];
        };

        extensions = with pkgs.vscode-marketplace; [
          augment.vscode-augment
          golang.go
          github.vscode-github-actions
          dracula-theme.theme-dracula
          jnoortheen.nix-ide
          vscodevim.vim
          llam4u.nerdtree
        ];
      };
    };
  };
}
