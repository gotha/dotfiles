{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.openwhispr;
  json = pkgs.formats.json { };
  python = pkgs.python3.withPackages (ps: [ ps.plyvel ]);
  settings = json.generate "openwhispr-settings.json" cfg.settings;
  hasSettings = cfg.settings.environment != { } || cfg.settings.localStorage != { };
  dictionary = json.generate "openwhispr-dictionary.json" cfg.dictionary;
  syncDictionary = pkgs.writeShellScriptBin "openwhispr-sync-dictionary" ''
    exec ${pkgs.python3}/bin/python3 ${./sync-dictionary.py} \
      ${dictionary} ${lib.escapeShellArg "${config.home.homeDirectory}/.openwhispr/cli-bridge.json"}
  '';
in
{
  options.programs.openwhispr = {
    enable = lib.mkEnableOption "OpenWhispr";
    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      description = ''
        OpenWhispr package to install. Leave null when the application is
        installed separately, for example through Homebrew or the upstream NixOS module.
      '';
    };
    dataDir = lib.mkOption {
      type = lib.types.str;
      default =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "${config.home.homeDirectory}/Library/Application Support/open-whispr"
        else
          "${config.xdg.configHome}/open-whispr";
      defaultText = lib.literalExpression ''
        if pkgs.stdenv.hostPlatform.isDarwin then
          "''${config.home.homeDirectory}/Library/Application Support/open-whispr"
        else
          "''${config.xdg.configHome}/open-whispr"
      '';
      description = ''
        OpenWhispr's writable user data directory. The default matches version
        1.10.2; override it if your build uses a different application name.
      '';
    };
    backupDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.xdg.stateHome}/openwhispr/home-manager-backups";
      defaultText = lib.literalExpression ''"''${config.xdg.stateHome}/openwhispr/home-manager-backups"'';
      description = "Directory for private backups made before settings are changed.";
    };
    dictionary = lib.mkOption {
      type = lib.types.listOf lib.types.nonEmptyStr;
      default = [ ];
      example = [
        "NixOS"
        "Home Manager"
      ];
      description = ''
        Words added through the running app's local CLI bridge. A user timer
        checks every minute; existing and auto-learned words are preserved.
        Removing a word here does not delete it from the app. Requires the
        CLI bridge shipped with OpenWhispr 1.10.2. Words enter the Nix store.
      '';
    };
    settings = {
      environment = lib.mkOption {
        type = lib.types.attrsOf lib.types.singleLineStr;
        default = { };
        example = {
          DICTATION_KEY = "RightCommand";
          ACTIVATION_MODE = "push";
        };
        description = ''
          Non-secret values merged into OpenWhispr's .env file on activation.
          Other variables are preserved. Values must be strings, including booleans.
          Do not put credentials here: these values enter the Nix store.
        '';
      };
      localStorage = lib.mkOption {
        type = lib.types.attrsOf json.type;
        default = { };
        example = {
          dictationKey = "RightCommand";
          activationMode = "push";
          audioCuesEnabled = true;
        };
        description = ''
          Non-secret preferences merged into Chromium localStorage on activation.
          Strings are stored verbatim; other JSON values are serialized to JSON.
          Unmanaged preferences are preserved. This uses OpenWhispr's internal
          storage format, verified with version 1.10.2, rather than a settings API.
          Do not copy credentials, account state, or permission grants here.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.all (key: builtins.match "[A-Z_][A-Z_0-9]*" key != null) (
          builtins.attrNames cfg.settings.environment
        );
        message = "programs.openwhispr.settings.environment names must match [A-Z_][A-Z_0-9]*.";
      }
      {
        assertion = lib.hasPrefix "/" cfg.dataDir && lib.hasPrefix "/" cfg.backupDir;
        message = "programs.openwhispr.dataDir and backupDir must be absolute paths.";
      }
    ];
    home.packages =
      lib.optional (cfg.package != null) cfg.package
      ++ lib.optional (cfg.dictionary != [ ]) syncDictionary;
    launchd.agents.openwhispr-dictionary =
      lib.mkIf (pkgs.stdenv.hostPlatform.isDarwin && cfg.dictionary != [ ])
        {
          enable = true;
          config = {
            ProgramArguments = [ "${syncDictionary}/bin/openwhispr-sync-dictionary" ];
            RunAtLoad = true;
            StartInterval = 60;
            ProcessType = "Background";
          };
        };
    systemd.user.services.openwhispr-dictionary =
      lib.mkIf (pkgs.stdenv.hostPlatform.isLinux && cfg.dictionary != [ ])
        {
          Unit.Description = "Add Home Manager dictionary words to OpenWhispr";
          Service = {
            Type = "oneshot";
            ExecStart = "${syncDictionary}/bin/openwhispr-sync-dictionary";
          };
        };
    systemd.user.timers.openwhispr-dictionary =
      lib.mkIf (pkgs.stdenv.hostPlatform.isLinux && cfg.dictionary != [ ])
        {
          Unit.Description = "Sync OpenWhispr dictionary while the app is running";
          Timer = {
            OnStartupSec = "15s";
            OnUnitActiveSec = "60s";
          };
          Install.WantedBy = [ "timers.target" ];
        };
    home.activation.openwhisprConfig = lib.mkIf hasSettings (
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${python}/bin/python3 ${./merge-settings.py} \
          ${settings} ${lib.escapeShellArg cfg.dataDir} \
          ${lib.escapeShellArg cfg.backupDir}
      ''
    );
  };
}
