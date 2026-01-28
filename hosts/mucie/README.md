# Mucie Host Configuration

This is the host configuration for the mucie macOS system using the platypus distro.

## WireGuard Setup

This host is configured to connect to the bastion WireGuard server.

### Initial Setup

1. **Create the wireguard directory:**

```bash
sudo mkdir -p /etc/wireguard
```

2. **Generate WireGuard keys for mucie:**

```bash
# Generate private key
wg genkey | sudo tee /etc/wireguard/mucie-private.key
sudo chmod 600 /etc/wireguard/mucie-private.key

# Generate public key from private key
sudo cat /etc/wireguard/mucie-private.key | wg pubkey
```

3. **Update the configuration with the public key:**

The public key has already been added to `config/wireguard.nix`. If you generated a different key, edit that file and replace the public key for the mucie peer (10.100.0.101).

4. **Deploy the configuration to bastion:**

The bastion server needs to be updated to allow the new mucie peer. Deploy the updated configuration:

```bash
# From the dotfiles directory
nix run github:serokell/deploy-rs -- .#bastion
```

5. **Apply the configuration on mucie:**

```bash
sudo darwin-rebuild switch --flake .
```

6. **Start the WireGuard interface:**

```bash
# Start the wg0 interface
sudo wg-quick up wg0

# Check status
sudo wg show
```

7. **Test the connection:**

```bash
# Ping the bastion server
ping 10.100.0.1

# Ping the lucie peer (if configured)
ping 10.100.0.100
```

### Managing WireGuard

**Start WireGuard:**
```bash
sudo wg-quick up wg0
```

**Stop WireGuard:**
```bash
sudo wg-quick down wg0
```

**Check status:**
```bash
sudo wg show
```

**View configuration:**
```bash
sudo wg showconf wg0
```

### Auto-start on Boot (Optional)

To automatically start WireGuard on boot, you can create a LaunchDaemon. However, this is not configured by default in nix-darwin's wg-quick module.

### Network Configuration

- **Mucie IP:** 10.100.0.101/24
- **Bastion IP:** 10.100.0.1/24 (server)
- **Lucie IP:** 10.100.0.100/24
- **Allowed IPs:** 10.100.0.0/24 (entire VPN network)

### Troubleshooting

**Connection issues:**
1. Check if the bastion server is running and accessible
2. Verify firewall rules allow UDP port 51820
3. Check the private key file exists and has correct permissions
4. Verify the public key in `config/wireguard.nix` matches your generated key

**View logs:**
```bash
# Check system logs for wg-quick
log show --predicate 'process == "wg-quick"' --last 1h
```

**Reset connection:**
```bash
sudo wg-quick down wg0
sudo wg-quick up wg0
```

### Current Configuration

The mucie peer is already configured with:
- Private IP: 10.100.0.101
- Public Key: NZETKMr9JawD+jJhc2+YJ5ORk3Xmq0SERu37NYq2KFE=

If you need to regenerate keys, make sure to update `config/wireguard.nix` with the new public key.

