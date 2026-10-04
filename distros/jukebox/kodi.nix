# Kodi as the whole session: no X, no Wayland compositor, no display manager.
#
# kodi-gbm renders straight onto KMS through GBM, which is both what LibreELEC
# does and what makes this viable on hardware as small as a Pi 3 - an X server
# underneath would cost memory and a frame of latency for nothing. nixpkgs'
# services.xserver.desktopManager.kodi only offers an X11 session, so the
# service below stands in for it rather than configuring it.
{
  lib,
  pkgs,
  username,
  ...
}:
let
  # Binary addons have to come from kodiPackages and be named here: Kodi's own
  # repository ships them built against an FHS layout, so installing one from
  # inside the UI silently fails. Python-only addons install from the UI as
  # normal and need no entry. Everything below has an aarch64-linux build in
  # the binary cache, so none of it adds to the Pi's build time.
  kodi = pkgs.kodi-gbm.withPackages (
    ps: with ps; [
      # Playback plumbing. inputstream-adaptive is what actually plays DASH and
      # HLS, which is what most streaming addons hand back; inputstreamhelper
      # is the addon the others call to check it is installed.
      inputstream-adaptive
      inputstreamhelper

      # Remaps remote buttons from inside Kodi's own UI. The one that pays off
      # the CEC work: a TV sends whatever it likes for back, info and the
      # colour keys, and this fixes it without hand-editing XML over ssh.
      keymap
      # Plays the next episode without being asked, which is the difference
      # between a remote and no remote from the sofa.
      upnext
      # Subtitle search that still works; the older OpenSubtitles addon mostly
      # does not.
      a4ksubtitles

      youtube
      # Skips sponsor segments in what youtube hands back.
      sponsorblock

      # Browse and play media straight off another box over ssh, with no share
      # to export and nothing to mount.
      vfs-sftp

      # Plex client.
      plex-for-kodi
    ]
  );
in
{
  hardware.graphics.enable = true;

  users.users.${username}.extraGroups = [
    "audio"
    "input"
    "tty"
    "video"
  ];

  # HDMI-CEC arrives as /dev/cec0, registered by the vc4 driver on a Pi and by
  # the display driver on anything else that has it. TAG+="uaccess" is what
  # makes it reachable: logind then puts an ACL for whoever holds the active
  # seat on the device, which is the Kodi session below. The group and mode are
  # the fallback for anything inspecting it outside a session, like cec-ctl run
  # over ssh.
  services.udev.extraRules = ''
    KERNEL=="cec[0-9]*", SUBSYSTEM=="cec", TAG+="uaccess", GROUP="video", MODE="0660"
  '';

  environment.systemPackages = [
    kodi
    # cec-client, for talking to the TV by hand when Kodi says nothing is
    # there: `echo scan | cec-client -s -d 1` lists every device on the bus.
    pkgs.libcec
    # cec-ctl, which is the lower-level view - it reports whether the kernel
    # registered an adapter at all, which separates "no CEC hardware" from
    # "CEC hardware, uncooperative TV".
    pkgs.v4l-utils
  ];

  systemd.services = {
    # Kodi owns tty1. It has to be the active VT to become DRM master, and a
    # getty on the same VT would both compete for the keyboard and flicker a
    # login prompt over the top of the UI.
    "getty@tty1".enable = false;
    "autovt@tty1".enable = false;

    kodi = {
      description = "Kodi media center";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network-online.target"
        "systemd-user-sessions.service"
      ];
      wants = [ "network-online.target" ];
      conflicts = [ "getty@tty1.service" ];

      serviceConfig = {
        ExecStart = lib.getExe' kodi "kodi-standalone";
        User = username;
        # PAMName = "login" is what makes the whole thing work: it opens a real
        # logind session on the seat that owns tty1, and only a session leader
        # gets DRM master plus the uaccess ACLs on /dev/dri/*, /dev/input/* and
        # /dev/cec0. Without it Kodi starts, finds no GPU it is allowed to drive,
        # and exits.
        PAMName = "login";
        TTYPath = "/dev/tty1";
        TTYReset = true;
        TTYVHangup = true;
        TTYVTDisallocate = true;
        StandardInput = "tty";
        StandardOutput = "journal";
        StandardError = "journal";
        Restart = "always";
        RestartSec = 5;
      };
    };
  };

  # Kodi's remote-control interfaces. 8080 is the web UI and the JSON-RPC
  # endpoint behind it, which is what the phone remotes drive; 9777 is the
  # older EventServer that some of them still speak. Both are off inside Kodi
  # until they are turned on under Settings > Services, so opening the ports
  # here only decides whether the LAN can reach them once they are.
  networking.firewall = {
    allowedTCPPorts = [ 8080 ];
    allowedUDPPorts = [ 9777 ];
  };
}
