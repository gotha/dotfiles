{ config, lib, pkgs, ... }:

{
  # Install Ollama
  home.packages = with pkgs; [ ollama ];

  # Configure Ollama as a LaunchAgent service
  launchd.agents.ollama = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    config = {
      ProgramArguments = [ "${pkgs.ollama}/bin/ollama" "serve" ];
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/ollama.log";
      StandardErrorPath =
        "${config.home.homeDirectory}/Library/Logs/ollama.log";

      # Optional: Set environment variables
      EnvironmentVariables = {
        # Uncomment and modify as needed
        OLLAMA_HOST = "127.0.0.1:11434";
        # OLLAMA_MODELS = "${config.home.homeDirectory}/.ollama/models";
      };
    };
  };
}
