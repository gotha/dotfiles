# transmission, plus the two directories it expects to already exist.
#
# Split out of ../../../distros/devbox so a distro can have the daemon without
# inheriting the rest of devbox along with it.
{ pkgs, username, ... }:
{
  services.transmission = {
    enable = true;
    package = pkgs.transmission_4;
    user = username;
    group = "users";
    webHome = pkgs.flood-for-transmission;
    openRPCPort = true;
    settings = {
      rpc-bind-address = "0.0.0.0";
      rpc-whitelist-enabled = false;
      download-dir = "/home/${username}/Downloads";
      incomplete-dir = "/home/${username}/Downloads/.incomplete";
      incomplete-dir-enabled = true;
    };
  };

  # transmission does not create download-dir or incomplete-dir itself.
  systemd.tmpfiles.rules = [
    "d /home/${username}/Downloads 0755 ${username} users -"
    "d /home/${username}/Downloads/.incomplete 0755 ${username} users -"
  ];
}
