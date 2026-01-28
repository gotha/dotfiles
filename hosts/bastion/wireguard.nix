{ config, pkgs, ... }:
let
  wireguard = import ../../config/wireguard.nix;
  bastion = wireguard.bastion;
  peers = builtins.map (peer: {
    publicKey = peer.publicKey;
    allowedIPs = [ "${peer.privateIP}/32" ];
  }) wireguard.peers;
in
{

  # Configure sops for secrets management
  sops = {
    # Use GPG keys from root's home directory
    gnupg.home = "/root/.gnupg";
    gnupg.sshKeyPaths = [ ];

    # Disable age
    age.sshKeyPaths = [ ];

    secrets.bastion_private_key = {
      sopsFile = ../../secrets/wg-bastion-key.enc;
      format = "json";
      key = "bastion_private_key";
      mode = "0400";
      owner = "root";
      group = "root";
    };
  };

  # Enable IP forwarding - needed so wg peers can communicate with each other
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = true;
    "net.ipv6.conf.all.forwarding" = true;
  };

  networking = {
    hostName = bastion.hostName;
    nat = {
      enable = true;
      externalInterface = "ens3";
      internalInterfaces = [ "wg0" ];
    };
    firewall = {
      allowedUDPPorts = [
        51820 # wireguard
      ];
      checkReversePath = false;
    };
    wireguard = {
      enable = true;
      interfaces = {
        wg0 = {
          # Determines the IP address and subnet of the server's end of the tunnel interface.
          ips = [ "${bastion.privateIP}/24" ];

          # The port that WireGuard listens to. Must be accessible by the client.
          listenPort = 51820;

          # This allows the wireguard server to route your traffic to the internet and hence be like a VPN
          # For this to work you have to set the dnsserver IP of your router (or dnsserver of choice) in your clients
          postSetup = ''
            ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.100.0.0/24 -o ens3 -j MASQUERADE
          '';

          # This undoes the above command
          postShutdown = ''
            ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.100.0.0/24 -o ens3 -j MASQUERADE
          '';

          privateKeyFile = config.sops.secrets.bastion_private_key.path;

          peers = peers;
        };
      };
    };
  };
}
