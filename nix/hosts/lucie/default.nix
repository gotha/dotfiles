{ pkgs, ... }:
let
  cfg = import ../../config/default.nix;
  username = cfg.username;
in {

  imports = [ ./hardware-configuration.nix ../../os/linux/efi.nix ];

  networking.hostName = "lucie";

  services = { xserver.videoDrivers = [ "nvidia" ]; };

  systemd.services.hg-tunnel = {
    enable = true;
    description = "Setup a secure tunnel to hgeorgiev.com";
    after = [ "network.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      User = username;
      ExecStart =
        "${pkgs.openssh}/bin/ssh -NT -o ServerAliveInterval=60 -o ExitOnForwardFailure=yes -R 2224:localhost:22 gotha@hgeorgiev.com";

      RestartSec = 5;
      Restart = "always";

      Type = "simple";
    };

    environment = { HOME = "/home/${username}"; };
  };

}
