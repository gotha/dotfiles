{
  config,
  wireguard,
  pkgs,
  username,
  ...
}:
{

  # Configure sops for secrets management
  sops = {
    # Use GPG keys from user's home directory
    gnupg.home = "/Users/${username}/.gnupg";
    gnupg.sshKeyPaths = [ ];

    # Disable age
    age.sshKeyPaths = [ ];

    secrets.mucie_private_key = {
      sopsFile = ../../secrets/wg-mucie-key.enc;
      format = "json";
      key = "private";
      mode = "0400";
    };
  };

  # Enable WireGuard using wg-quick for macOS
  networking.wg-quick.interfaces = {
    wg0 = {
      # Client's IP address in the VPN network
      address = [ "10.100.0.101/24" ];

      # DNS servers to use when connected (optional)
      # dns = [ "1.1.1.1" "8.8.8.8" ];

      # Path to the private key file
      # You'll need to generate this with: wg genkey > /etc/wireguard/mucie-private.key
      # And set proper permissions: sudo chmod 600 /etc/wireguard/mucie-private.key
      #privateKeyFile = "/etc/wireguard/mucie-private.key";
      privateKeyFile = config.sops.secrets.mucie_private_key.path;

      peers = [
        {
          # Public key of the bastion server
          publicKey = wireguard.bastion.publicKey;

          # Allow traffic to the entire VPN network
          allowedIPs = [ "10.100.0.0/24" ];

          # Bastion server endpoint
          endpoint = "${wireguard.bastion.publicIP}:51820";

          # Send keepalives every 25 seconds to keep NAT tables alive
          persistentKeepalive = 25;
        }
      ];
    };
  };
}
