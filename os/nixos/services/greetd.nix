# greetd with tuigreet in front of it.
#
# custom.defaultSession decides what pressing enter does. A command string goes
# straight to --cmd; null leaves tuigreet showing its session picker, built from
# the desktop files of every compositor the system has enabled. The picker is
# the way back in when the default session is the thing that is broken.
{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  cfg = config.services.greetd.custom;
  sessions = "${config.services.displayManager.sessionData.desktops}/share/wayland-sessions";
in
{
  options.services.greetd.custom.defaultSession = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    example = "sway --unsupported-gpu";
    description = ''
      Command tuigreet runs on enter. When null, tuigreet shows the session
      picker instead and remembers the last choice.
    '';
  };

  config.services.greetd = {
    enable = true;
    settings.default_session = {
      command =
        "${pkgs.tuigreet}/bin/tuigreet --time "
        + (
          if cfg.defaultSession == null then
            "--remember-session --sessions ${sessions}"
          else
            "--cmd '${cfg.defaultSession}'"
        );
      user = username;
    };
  };
}
