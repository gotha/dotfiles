# Wireguard setup

## Generate keys for new peer

```sh
# generate private key
wg genkey > privatekey
# Generate public key from private key
wg pubkey < privatekey > publickey
```

## Add new peer

add new peer in the config file:

```config/wireguard.nix
...
{
  privateIP = "10.100.0.X";
  publicKey = "<public key value>";
}
...
```

and re-deploy the bastion configuration

```sh
nix run github:serokell/deploy-rs -- .#bastion
```

### Configure the peer

The configuration should look like this:

```wireguard-peer.conf
[Interface]
PrivateKey = <new peer private key>
Address = 10.100.0.X/24
DNS = 1.1.1.1

[Peer]
PublicKey = <bastion public key>
Endpoint = <bastion IP>:51820
AllowedIPs = 10.100.0.0/24
PersistentKeepalive = 25
```

if the device is running Nix, look at `./hosts/` folder for examples on how to configure

### Add new peer via QR code

On mobile devices, the easiest way is via QR code.

```
qrencode -o wireguard-peer.png < wireguard-peer.conf
```

1. Open WireGuard on iOS
2. Tap + (Add a tunnel)
3. Select "Create from QR code"
4. Scan the QR code above
