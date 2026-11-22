# Session restore: the apps that were open, back on the workspaces they were on.
#
# This replaces the fixed list of autostarted apps that ../hyprland/hyprland.lua
# used to carry, which could only ever open one window per app. hypr-layout
# launches one process per *saved window*, so three terminals on three
# workspaces come back as three.
#
# Upstream is a single stdlib-only python file, so there is nothing to build and
# no plugin ABI to chase across hyprland releases. It needs `hyprctl` at
# runtime, which programs.hyprland provides system-wide.
{ pkgs, lib, ... }:
let
  hypr-layout = pkgs.stdenvNoCC.mkDerivation {
    pname = "hypr-layout";
    version = "0-unstable-2026-09-14";

    src = pkgs.fetchFromGitHub {
      owner = "leftydevkit";
      repo = "hypr-layout";
      rev = "f51756f4ba6d865c45c2ef2dcef12314dd04b5d4";
      hash = "sha256-WsrvPIeynyEdtzVPJRIb4XPIvrD6PN0TuYRLTflOjRM=";
    };

    # Only to resolve the `#!/usr/bin/env python3` shebang at build time.
    nativeBuildInputs = [ pkgs.python3 ];
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 hypr-layout $out/bin/hypr-layout
      patchShebangs $out/bin/hypr-layout
      runHook postInstall
    '';

    meta = {
      description = "Snapshot and replay the hyprland window layout";
      homepage = "https://github.com/leftydevkit/hypr-layout";
      license = lib.licenses.mit;
      mainProgram = "hypr-layout";
      platforms = lib.platforms.linux;
    };
  };
in
{
  home.packages = [ hypr-layout ];

  # The tool is a CLI, not a daemon, so nothing snapshots on its own. A crash
  # therefore costs at most the last two minutes of window changes, and every
  # save rotates into a pruned ~/.config/hypr/layout-history to restore from.
  systemd.user.services.hypr-layout-save = {
    Unit = {
      Description = "Snapshot the hyprland window layout";
      PartOf = [ "hyprland-session.target" ];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${lib.getExe hypr-layout} save";
    };
  };

  # Bound to the session rather than timers.target: outside hyprland there is
  # no socket to read and every firing would only log a failure.
  systemd.user.timers.hypr-layout-save = {
    Unit = {
      Description = "Snapshot the hyprland window layout every two minutes";
      PartOf = [ "hyprland-session.target" ];
    };

    Timer = {
      OnActiveSec = "2min";
      OnUnitActiveSec = "2min";
    };

    Install.WantedBy = [ "hyprland-session.target" ];
  };
}
