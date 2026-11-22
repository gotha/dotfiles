# System-wide mpd, running as the login user so it can read ~/Music.
#
# The user half - mpdris2 on Linux, a launchd agent on darwin - is over in
# ../../../home-manager/mpd and is not tied to this module.
{ username, ... }:
{
  services.mpd = {
    enable = true;
    user = username;
    group = "users";
    settings = {
      music_directory = "/home/${username}/Music";
      audio_output = [
        {
          type = "pipewire";
          name = "PipeWire Sound Server";
        }
      ];
    };
  };

  # pipewire's socket sits under XDG_RUNTIME_DIR, which a system service is not
  # given. Without this mpd starts fine and then has nowhere to play.
  systemd.services.mpd.environment.XDG_RUNTIME_DIR = "/run/user/1000";
}
