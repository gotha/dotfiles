# Thunar's looks.
#
# Thunar is a plain GTK3 app with no theming of its own: it draws whatever the
# GTK theme, icon theme and font say, which is why it looks like 2012 out of the
# box - the fallback is Adwaita-light with hicolor icons.
#
# So this module is really the GTK setup, and it applies to every GTK app in the
# session (file chooser dialogs, pavucontrol, wlogout). That is the point: one
# look, not a themed Thunar sitting next to unthemed dialogs.
#
# Colloid in its nord tweak, teal accent, to match ../hyprland/hyprland.lua -
# its borders are #88c0d0 -> #5e81ac on #2e3440, and hy3's tab bar follows the
# same palette. The cursor is the xcursor build of the rose-pine hyprcursor
# that hyprland.lua already sets, so the pointer does not change shape when it
# crosses from the compositor into a window.
#
# The app itself is enabled at system level (programs.thunar in
# ../../distros/h4kbox), because the plugins, the D-Bus service and gvfs are
# NixOS-side.
{ pkgs, ... }:
let
  gtkTheme = pkgs.colloid-gtk-theme.override {
    themeVariants = [ "teal" ];
    colorVariants = [ "dark" ];
    # rimless drops the 1px outlines that make GTK3 look dated; nord repaints
    # the whole thing in the palette hyprland already uses.
    tweaks = [
      "nord"
      "rimless"
    ];
  };

  iconTheme = pkgs.colloid-icon-theme.override {
    schemeVariants = [ "nord" ];
    colorVariants = [ "teal" ];
  };
in
{
  gtk = {
    enable = true;

    theme = {
      name = "Colloid-Teal-Dark-Nord";
      package = gtkTheme;
    };

    iconTheme = {
      name = "Colloid-Teal-Nord-Dark";
      package = iconTheme;
    };

    cursorTheme = {
      name = "BreezeX-RosePine-Linux";
      package = pkgs.rose-pine-cursor;
      size = 24;
    };

    font = {
      name = "Inter";
      package = pkgs.inter;
      size = 10;
    };

    # Dark everywhere. The theme is already the dark build, but GTK apps that
    # ship both variants pick by this flag, not by the theme name.
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
      gtk-decoration-layout = "appmenu:minimize,maximize,close";
    };

    # Colloid ships gtk-4.0 assets, so GTK4 apps get it too. Stated outright
    # because the default for this flips to null once stateVersion reaches
    # 26.05, and silence here would mean untheming them on a future bump.
    gtk4.theme = {
      name = "Colloid-Teal-Dark-Nord";
      package = gtkTheme;
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
      gtk-decoration-layout = "appmenu:minimize,maximize,close";
    };
  };

  # libadwaita apps ignore the GTK theme entirely and read this instead, so
  # without it a GTK4 file dialog opens bright white over a dark Thunar.
  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    gtk-theme = "Colloid-Teal-Dark-Nord";
    icon-theme = "Colloid-Teal-Nord-Dark";
    cursor-theme = "BreezeX-RosePine-Linux";
    font-name = "Inter 10";
  };

  # Qt apps (pavucontrol-qt and friends) follow the platform theme, not GTK.
  qt = {
    enable = true;
    # "gtk" is deprecated and resolved to this anyway: the native Qt GTK3
    # plugin, not the old qtstyleplugins path that "gtk2" still selects.
    platformTheme.name = "gtk3";
  };

  # Thunar's own view defaults. Without these it opens in a cramped list with
  # thumbnails off, which reads as "ugly" as much as the theme does.
  xfconf.settings.thunar = {
    "last-view" = "ThunarIconView";
    "last-icon-view-zoom-level" = "THUNAR_ZOOM_LEVEL_150_PERCENT";
    "last-details-view-zoom-level" = "THUNAR_ZOOM_LEVEL_38_PERCENT";
    "last-side-pane" = "ThunarShortcutsPane";
    "last-separator-position" = 170;
    "last-window-maximized" = false;
    "misc-thumbnail-mode" = "THUNAR_THUMBNAIL_MODE_ALWAYS";
    "misc-folders-first" = true;
    "misc-single-click" = false;
    "misc-date-style" = "THUNAR_DATE_STYLE_SHORT";
    "misc-text-beside-icons" = false;
    "misc-middle-click-in-tab" = true;
    "misc-open-new-window-as-tab" = true;
  };

  # The three themes above are installed by gtk.{theme,iconTheme,cursorTheme}
  # .package already - listing them here too just puts them in the profile
  # twice. Only the fallback needs adding: Colloid covers every freedesktop
  # icon name, but third-party apps ask for names nobody has drawn for it, and
  # without somewhere for the lookup chain to end those render as a blank
  # square.
  home.packages = [ pkgs.adwaita-icon-theme ];
}
