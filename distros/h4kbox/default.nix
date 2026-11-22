# devbox with hyprland in place of sway.
#
# Layered on top of ./distros/devbox (see distro.h4kbox in flake.nix), so
# anything added to devbox lands here too. sway is left installed on purpose:
# the greeter's session picker is the way back out of a hyprland config that
# does not start.
{
  config,
  lib,
  pkgs,
  username,
  ...
}:
{
  # Upstream's cache. Everything hypr* that this distro uses already comes from
  # cache.nixos.org, so this only earns its keep once something here is built
  # from the hyprland flake instead of nixpkgs.
  nix.settings = {
    extra-substituters = [ "https://hyprland.cachix.org" ];
    extra-trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
  };

  programs = {
    hyprland.enable = true;
    # PAM for the lock screen, and it pulls in the hypridle user service.
    hyprlock.enable = true;

    # The file manager. System-level because the module wires the plugins and
    # Thunar's D-Bus service; its looks come from ../../home-manager/thunar.
    thunar = {
      enable = true;
      plugins = with pkgs; [
        thunar-archive-plugin # "Extract here" in the context menu
        thunar-volman # act on plugged-in media
      ];
    };
  };

  # Thunar on its own can browse and nothing else. Without these three it has
  # no trash, cannot mount a USB stick, and shows a generic icon in place of
  # every thumbnail - all of which read as the file manager being broken.
  services = {
    gvfs.enable = true; # trash, mounts, remote shares
    tumbler.enable = true; # thumbnails
    udisks2.enable = true; # removable media
  };

  # What "default file manager" actually means: the mime handler other apps go
  # through when they open a folder. Thunar being installed does not set it.
  xdg.mime.defaultApplications = {
    "inode/directory" = "thunar.desktop";
    "x-directory/normal" = "thunar.desktop";
  };

  # No --cmd: with sway still installed, the session picker is the escape hatch.
  # The desktop files live in sessionData.desktops, not in the system path.
  services.greetd.settings.default_session.command = lib.mkForce (
    "${pkgs.tuigreet}/bin/tuigreet --time --remember-session "
    + "--sessions ${config.services.displayManager.sessionData.desktops}/share/wayland-sessions"
  );

  # Without this hm aborts the whole generation on any unmanaged file in its way.
  home-manager.backupFileExtension = "backup";

  home-manager.users.${username} = {
    imports = [
      ../../home-manager/hypridle
      ../../home-manager/hypr-layout
      ../../home-manager/hyprland
      ../../home-manager/hyprlock
      ../../home-manager/hyprpaper
      ../../home-manager/quickshell
      ../../home-manager/thunar
    ];

    # Everything else devbox imports - aerc, nvim, zsh, kitty, mako and the
    # rest - comes through the layering untouched. ../../os/* needs nothing
    # either, for the same reason: devbox already imports it.
    #
    # Three go. sway's own module - devbox reaches it through ../../home-manager/swayfx,
    # so both paths have to be named here - and waybar, whose workspace and window
    # modules only speak sway's IPC - quickshell replaces the bar, and hypr*
    # replaces swaylock, swayidle and wob. Then rofi, which hyprlauncher
    # replaces for both the launcher and the clipboard picker.
    disabledModules = [
      ../../home-manager/swayfx
      ../../home-manager/sway
      ../../home-manager/waybar
      ../../home-manager/rofi
    ];
  };
}
