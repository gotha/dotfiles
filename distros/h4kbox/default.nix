# h4kbox: devbox with Hyprland and quickshell in place of sway and waybar.
#
# Layered on top of ./distros/devbox rather than forking it (see distro.h4kbox
# in flake.nix), for the same reason ../devbox-arm is: anything added to devbox
# lands here too, and devbox itself is untouched, so it cannot regress because
# of a change made for h4kbox.
#
# Everything else devbox provides - the package set, 1password, firefox
# policies, obs, pipewire, transmission, luna-podcatcher, keyd, dictation - is
# inherited unchanged. Only the compositor and the bar differ.
{
  lib,
  pkgs,
  username,
  ...
}:
{
  # sway's NixOS module wires up a session, a portal and wrapper scripts, none
  # of which should be present when Hyprland owns the seat.
  programs.sway.enable = lib.mkForce false;

  # Hyprland's own module supplies the binary, the session entry, polkit and
  # xdg-desktop-portal-hyprland, which is why ../../home-manager/hyprland does
  # not put the compositor in home.packages.
  programs.hyprland.enable = true;

  # greetd launches the compositor directly, so the session it starts has to
  # change with it. sway needed --unsupported-gpu to accept llvmpipe; Hyprland
  # takes software rendering without a flag, and the pieces it does need in a
  # VM (software cursors, WLR_RENDERER_ALLOW_SOFTWARE) live in hyprland.conf so
  # they apply however the session is started.
  services.greetd.settings.default_session.command =
    lib.mkForce "${pkgs.tuigreet}/bin/tuigreet --time --cmd Hyprland";

  home-manager.users.${username} = {
    # disabledModules un-imports these from the list devbox builds, so their
    # packages and config files go with them - waybar would otherwise start
    # alongside quickshell, and the sway module would keep writing
    # ~/.config/sway/config and its own copy of the custom xkb layouts.
    disabledModules = [
      ../../home-manager/sway
      ../../home-manager/waybar
    ];

    imports = [
      ../../home-manager/hyprland
      ../../home-manager/quickshell
    ];
  };
}
