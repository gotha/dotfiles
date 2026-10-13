{ config, wireguard, ... }:
{
  sops.secrets.thucie_private_key = {
    sopsFile = ./secrets/wg-thucie-key.enc;
    format = "json";
    key = "private";
    mode = "0400";
  };

  networking.wireguard.interfaces.wg0 = {
    ips = [ "10.100.0.102/24" ];
    privateKeyFile = config.sops.secrets.thucie_private_key.path;

    peers = [
      {
        name = "bastion";
        inherit (wireguard.bastion) publicKey;
        allowedIPs = [ "10.100.0.0/24" ];
        endpoint = "${wireguard.bastion.publicIP}:51820";
        persistentKeepalive = 25;
      }
    ];
  };
}
