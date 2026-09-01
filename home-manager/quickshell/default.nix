# quickshell for h4kbox - the bar, replacing waybar.
#
# quickshell is a QtQuick shell toolkit rather than a bar with a config file, so
# the "config" is QML. ./shell.qml is the whole bar; quickshell picks up
# ~/.config/quickshell/shell.qml by default, so no launch arguments are needed
# and hyprland.conf just does `exec-once = quickshell`.
#
# The font is "Hack Nerd Font", already provided system-wide by
# ../../config/fonts.nix (nerd-fonts.hack), same as the waybar module used.
{ pkgs, ... }:
{

  home = {
    packages = with pkgs; [
      quickshell

      # quickshell exposes pipewire and tray data to QML, but the bar in
      # shell.qml does not use them yet - these are the tools to poke at audio
      # while extending it, and the ones waybar pulled in for the same reason.
      pavucontrol
      playerctl
    ];
  };

  xdg.configFile."quickshell/shell.qml".source = ./shell.qml;
}
