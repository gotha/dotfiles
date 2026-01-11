{ pkgs, ... }:
{
  # KDE autostart applications
  # These applications will start automatically when KDE Plasma starts
  
  xdg.configFile = {
    # 1Password
    "autostart/1password.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Exec=1password
      Hidden=false
      NoDisplay=false
      X-GNOME-Autostart-enabled=true
      Name=1Password
    '';
    
    # Alacritty terminal
    "autostart/alacritty.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Exec=alacritty
      Hidden=false
      NoDisplay=false
      X-GNOME-Autostart-enabled=true
      Name=Alacritty
    '';
    
    # Discord
    "autostart/discord.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Exec=discord
      Hidden=false
      NoDisplay=false
      X-GNOME-Autostart-enabled=true
      Name=Discord
    '';
    
    # Firefox
    "autostart/firefox.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Exec=firefox
      Hidden=false
      NoDisplay=false
      X-GNOME-Autostart-enabled=true
      Name=Firefox
    '';
    
    # Slack
    "autostart/slack.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Exec=slack
      Hidden=false
      NoDisplay=false
      X-GNOME-Autostart-enabled=true
      Name=Slack
    '';
    
    # Spotify
    "autostart/spotify.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Exec=spotify
      Hidden=false
      NoDisplay=false
      X-GNOME-Autostart-enabled=true
      Name=Spotify
    '';
    
    # Transmission
    "autostart/transmission-gtk.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Exec=transmission-gtk
      Hidden=false
      NoDisplay=false
      X-GNOME-Autostart-enabled=true
      Name=Transmission
    '';

    # Remap Escape to Tilde (matching Sway configuration)
    "autostart/remap-escape.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Exec=${./scripts/remap-escape.sh}
      Hidden=false
      NoDisplay=false
      X-GNOME-Autostart-enabled=true
      Name=Remap Escape Key
    '';
  };
}

