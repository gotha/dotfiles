{ config, pkgs, ... }:
let
  wireguard = import ../../config/wireguard.nix;
  inherit (wireguard) bastion;
  peers = builtins.map (peer: {
    inherit (peer) publicKey;
    allowedIPs = [ "${peer.privateIP}/32" ];
  }) wireguard.peers;
in
{

  # No key configuration here on purpose. The default is
  # age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ], so root decrypts at
  # boot with the key sshd already has, and this machine holds no pgp key for a
  # snapshot or a stolen backup to give away.
  sops = {

    secrets.bastion_private_key = {
      sopsFile = ./secrets/wg-bastion-key.enc;
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
    inherit (bastion) hostName;
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
          # The second rule is what lets one peer reach another - every
          # .internal service is served from lucie and reached this way.
          # Forwarding already worked by falling through to the FORWARD chain's
          # default ACCEPT policy; stating it means a future change to that
          # policy cannot silently cut every peer off from lucie.
          postSetup = ''
            ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.100.0.0/24 -o ens3 -j MASQUERADE
            ${pkgs.iptables}/bin/iptables -A FORWARD -i wg0 -o wg0 -j ACCEPT
          '';

          # This undoes the above commands
          postShutdown = ''
            ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.100.0.0/24 -o ens3 -j MASQUERADE
            ${pkgs.iptables}/bin/iptables -D FORWARD -i wg0 -o wg0 -j ACCEPT
          '';

          privateKeyFile = config.sops.secrets.bastion_private_key.path;

          inherit peers;
        };
      };
    };
  };
}
