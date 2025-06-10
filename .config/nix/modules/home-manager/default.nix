{ pkgs, ... }: {
  home.stateVersion = "24.05";

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

        };

        extensions = with pkgs.vscode-marketplace; [
          augment.vscode-augment
          golang.go
          dracula-theme.theme-dracula
          jnoortheen.nix-ide
          vscodevim.vim
        ];
      };
    };
  };
}
