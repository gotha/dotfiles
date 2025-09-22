{ wireguard, ... }: {

  networking.wireguard = {
    enable = true;
    interfaces = {
      wg0 = {
        # Determines the IP address and subnet of the client's end of the tunnel interface.
        ips = [ "10.100.0.100/24" ];
        listenPort =
          51820; # to match firewall allowedUDPPorts (without this wg uses random port numbers)

        # Path to the private key file.
        #
        # Note: The private key can also be included inline via the privateKey option,
        # but this makes the private key world-readable; thus, using privateKeyFile is
        # recommended.
        privateKeyFile = "/etc/wireguard/private.key";

        peers = [
          # For a client configuration, one peer entry for the server will suffice.

          {
            # Public key of the bastion server (not a file path).
            publicKey = wireguard.bastionPublicKey;

            # Forward all the traffic via VPN.
            #allowedIPs = [ "0.0.0.0/0" ];
            # enitre network
            allowedIPs = [ "10.100.0.0/24" ];
            # single ip
            #allowedIPs = [ "10.100.0.1" ];
            # Or forward only particular subnets
            #allowedIPs = [ "10.100.0.1" "91.108.12.0/22" ];

            name = "bastion";
            # Set this to the server IP and port.
            endpoint =
              "${wireguard.bastionPublicIp}:51820"; # ToDo: route to endpoint not automatically configured https://wiki.archlinux.org/index.php/WireGuard#Loop_routing https://discourse.nixos.org/t/solved-minimal-firewall-setup-for-wireguard-client/7577

            # Send keepalives every 25 seconds. Important to keep NAT tables alive.
            persistentKeepalive = 25;
          }
        ];
      };
    };
  };
}
