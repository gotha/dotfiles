{ ... }:
{
  # KDE Window Rules configuration
  # This file defines rules for window placement and behavior
  # Similar to i3/Sway assign commands and AeroSpace on-window-detected

  xdg.configFile."kwinrulesrc" = {
    force = false;  # Allow KDE to modify this file
    text = ''
      # Rule for Alacritty - always on Desktop 2
      [1]
      Description=Alacritty on Desktop 2
      # Desktop assignment (virtual desktop ID, starting from 1)
      desktops=2
      # Rule type: 3 = Force (always apply)
      desktopsrule=3
      # Window class matching
      wmclass=alacritty
      wmclassmatch=1
      # Additional settings to keep window on desktop 2
      # skippager: don't show in pager
      skippager=false
      skippagerrule=2
      # skiptaskbar: don't show in taskbar
      skiptaskbar=false
      skiptaskbarrule=2

      # General rule settings
      [General]
      count=1
      rules=1
    '';
  };
}

