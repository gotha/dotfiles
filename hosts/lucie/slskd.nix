# Soulseek daemon. Web UI at slskd.internal, via the map in internal.nix.
{ config, username, ... }:
{
  # One file rather than four secrets: systemd takes a single EnvironmentFile.
  # Holds SLSKD_SLSK_USERNAME/SLSKD_SLSK_PASSWORD for the Soulseek account and
  # SLSKD_USERNAME/SLSKD_PASSWORD for the web UI, which otherwise defaults to
  # slskd/slskd.
  sops.secrets.slskd_env = {
    sopsFile = ./secrets/slskd.env.enc;
    format = "binary";
    mode = "0400";
  };

  systemd.tmpfiles.rules = [
    "d /mnt/storage/slsk 0755 ${username} users -"
    "d /mnt/storage/slsk/.incomplete 0755 ${username} users -"
  ];

  services.slskd = {
    enable = true;

    # Runs as the owner of /mnt/storage, like plex and jellyfin here: downloads
    # land beside what is already in slsk/ and stay readable to mpd.
    user = username;
    group = "users";

    environmentFile = config.sops.secrets.slskd_env.path;

    # Only reaches a peer that can accept our outbound connection until 50300
    # is forwarded on the router.
    openFirewall = true;

    settings = {
      web.port = 5030;
      directories = {
        downloads = "/mnt/storage/slsk";
        incomplete = "/mnt/storage/slsk/.incomplete";
      };
      shares.directories = [ "/mnt/storage/Music" ];
    };
  };
}
