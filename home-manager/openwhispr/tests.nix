{ pkgs, home-manager }:
let
  inherit (pkgs) lib;
  homeDirectory = if pkgs.stdenv.hostPlatform.isDarwin then "/Users/test" else "/home/test";
  evaluate =
    modules:
    (home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        ./default.nix
        {
          home = {
            username = "test";
            inherit homeDirectory;
            stateVersion = "25.05";
          };
        }
      ]
      ++ modules;
    }).config;
  disabled = evaluate [ ];
  empty = evaluate [ { programs.openwhispr.enable = true; } ];
  configured = evaluate [
    {
      programs.openwhispr = {
        enable = true;
        settings = import ./settings.nix;
        dictionary = import ./dictionary.nix;
      };
    }
    ({ lib, ... }: {
      programs.openwhispr.settings = {
        environment.DICTATION_KEY = lib.mkForce "F8";
        localStorage.dictationKey = lib.mkForce "F8";
        localStorage.extraPreference = true;
      };
    })
  ];
  customPaths = evaluate [
    {
      xdg.configHome = "${homeDirectory}/custom config";
      xdg.stateHome = "${homeDirectory}/custom state";
      programs.openwhispr.enable = true;
    }
  ];
  packaged = evaluate [
    {
      programs.openwhispr = {
        enable = true;
        package = pkgs.hello;
      };
    }
  ];
  invalidName = evaluate [
    {
      programs.openwhispr = {
        enable = true;
        settings.environment."INVALID-NAME" = "value";
      };
    }
  ];
  invalidValue = evaluate [
    { programs.openwhispr.settings.environment.START_MINIMIZED = true; }
  ];
  python = pkgs.python3.withPackages (ps: [ ps.plyvel ]);
in
assert !disabled.programs.openwhispr.enable;
assert !(disabled.home.activation ? openwhisprConfig);
assert !(empty.home.activation ? openwhisprConfig);
assert !(empty.launchd.agents ? openwhispr-dictionary);
assert !(empty.systemd.user.timers ? openwhispr-dictionary);
assert
  if pkgs.stdenv.hostPlatform.isDarwin then
    configured.launchd.agents.openwhispr-dictionary.config.StartInterval == 60
    && !(configured.systemd.user.timers ? openwhispr-dictionary)
  else
    configured.systemd.user.timers.openwhispr-dictionary.Timer.OnUnitActiveSec == "60s"
    && !(configured.launchd.agents ? openwhispr-dictionary);
assert
  empty.programs.openwhispr.settings == {
    environment = { };
    localStorage = { };
  };
assert configured.home.activation ? openwhisprConfig;
assert lib.all (entry: entry.assertion) configured.assertions;
assert configured.programs.openwhispr.settings.environment.DICTATION_KEY == "F8";
assert configured.programs.openwhispr.settings.localStorage.dictationKey == "F8";
assert configured.programs.openwhispr.settings.localStorage.extraPreference;
assert configured.programs.openwhispr.settings.localStorage.cleanupModel == "qwen3.5-9b-q4_k_m";
assert
  customPaths.programs.openwhispr.dataDir == (
    if pkgs.stdenv.hostPlatform.isDarwin then
      "${homeDirectory}/Library/Application Support/open-whispr"
    else
      "${homeDirectory}/custom config/open-whispr"
  );
assert
  customPaths.programs.openwhispr.backupDir
  == "${homeDirectory}/custom state/openwhispr/home-manager-backups";
assert builtins.elem pkgs.hello packaged.home.packages;
assert !(builtins.tryEval invalidName.programs.openwhispr.enable).success;
assert
  !(builtins.tryEval invalidValue.programs.openwhispr.settings.environment.START_MINIMIZED).success;
pkgs.runCommand "openwhispr-module-tests" { } ''
  ${python}/bin/python3 -B ${./.}/test_merge_settings.py
  ${python}/bin/python3 -B ${./.}/test_sync_dictionary.py
  touch $out
''
