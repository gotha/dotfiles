# Adding a host

Two distros, and the choice is made for you by the machine:

| distro | for | declared under |
| --- | --- | --- |
| `devbox` | NixOS, x86_64 or aarch64 | `nixosConfigurations` |
| `platypus` | macOS, aarch64-darwin | `darwinConfigurations` |

Both pull in the same `home-manager/*` modules, so a new host gets the same
shell, editor, git and mail setup as the others. What differs is the system
layer around it.

Throughout, replace `newhost` with the machine's name. Pick something short
that can serve as both the directory under `hosts/` and the hostname.

---

## 1. Create the host directory

The directory is the machine's own configuration: everything the distro does
not already cover.

### NixOS (devbox)

Generate the hardware config on the machine itself, after installing NixOS:

```sh
nixos-generate-config --show-hardware-config > hardware-configuration.nix
```

Copy it into `hosts/newhost/`, then write `hosts/newhost/default.nix`:

```nix
{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../os/linux/efi.nix          # drop if the machine boots BIOS
  ];

  networking.hostName = "newhost";
}
```

No `system.stateVersion` here - `distros/devbox` already sets it. Only add one
if this machine was installed from a different NixOS release than the distro
declares, and then never bump it: it records the release the machine was
installed from, not one to keep current.

### macOS (platypus)

No hardware config. `hosts/newhost/default.nix` can be almost empty:

```nix
{ ... }:
{
  # Most configuration comes from the platypus distro.
}
```

Install nix and nix-darwin on the Mac first; see `README-darwin.md`.

---

## 2. Register it in the flake

In `flake.nix`, alongside the existing entries.

NixOS, under `nixosConfigurations`:

```nix
newhost = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = distro.devbox ++ [ ./hosts/newhost ];
  specialArgs = {
    inherit sops-nix;
    stablePkgs = import nixpkgs-stable {
      system = "x86_64-linux";
      config.allowUnfree = true;
    };
  };
};
```

macOS, under `darwinConfigurations`. The attribute name must be the machine's
**hostname** as `scutil --get LocalHostName` reports it, because
`darwin-rebuild` looks itself up by that name:

```nix
"NEWHOST-NAME" = darwin.lib.darwinSystem {
  system = "aarch64-darwin";
  modules = distro.platypus ++ [ ./hosts/newhost ];
  specialArgs = {
    inherit sops-nix;
    stablePkgs = import nixpkgs-stable {
      system = "aarch64-darwin";
      config.allowUnfree = true;
    };
  };
};
```

Check it evaluates before going near the machine:

```sh
nix eval .#nixosConfigurations.newhost.config.system.build.toplevel --raw
nix flake check .
```

---

## 3. Give it a secrets key

Without this the host builds but cannot decrypt anything, and activation fails
on the first module that wants a secret.

There are two kinds of key and a host may need one or both. Which one depends
on *who* does the decrypting, not on what the secret is.

### If the machine runs home-manager modules that use secrets

Activation runs as your user, so it needs a workstation key. Generate it **on
the new machine** - never copy one in:

```sh
mkdir -p ~/.config/sops/age
nix shell nixpkgs#age -c age-keygen -o ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt
grep 'public key' ~/.config/sops/age/keys.txt
```

Add that `age1...` to the `keys:` block in `.sops.yaml` as
`&ws_newhost`, and reference it from the `home-manager/[^/]+/secrets/` rule.

### If the machine has its own system-level secrets

Anything declared in `hosts/newhost/*.nix` is decrypted by root at boot, which
cannot read your home directory. That uses the machine's ssh host key, which
already exists - nothing to generate:

```sh
ssh newhost cat /etc/ssh/ssh_host_ed25519_key.pub | nix run nixpkgs#ssh-to-age
```

Add it as `&host_newhost` and give the host its own rule:

```yaml
- path_regex: hosts/newhost/secrets/
  unencrypted_regex: "^(apiVersion|metadata|kind|type)$"
  key_groups:
    - age:
        - *host_newhost
        - *breakglass
```

Scoped to that one host, so a compromise there does not reach any other
machine's secrets.

### Re-encrypt

Adding a recipient to `.sops.yaml` changes nothing on its own - the files carry
their own recipient lists. Sync them:

```sh
for f in $(git ls-files 'home-manager/*/secrets/*'); do sops updatekeys -y "$f"; done
```

`*.env.enc` files need `--input-type dotenv`; sops guesses wrong from the
extension and fails with `Could not unmarshal input data`.

This rewrites only the wrapped data key. No secret value changes, and you are
never shown one. Run it from a machine that is already a recipient - the new
host cannot re-key files it cannot yet read.

A host with no system secrets of its own needs no host key and no rule. Add
them later if that changes.

---

## 4. Optional: join the wireguard network

The network is a hub, not a mesh: every peer holds one `[Peer]` entry for
bastion, and bastion routes between them. So a new peer means an entry on
bastion **and** a config on the peer.

### 4.1 Generate the peer key

```sh
wg genkey | tee /tmp/privatekey | wg pubkey
```

### 4.2 Store the private half with sops

Put it in `hosts/newhost/secrets/wg-newhost-key.enc`:

```sh
echo '{"private":"<the private key>"}' > /tmp/wg.json
sops -e /tmp/wg.json > hosts/newhost/secrets/wg-newhost-key.enc
shred -u /tmp/wg.json /tmp/privatekey
```

This needs the `hosts/newhost/secrets/` rule from step 3, and it is why a
wireguard peer needs a host key even if it has no other system secrets.

`hosts/lucie/wireguard.nix` does this differently - it reads
`/etc/wireguard/private.key`, a file placed by hand and tracked nowhere. Follow
mucie and bastion instead; the sops route survives a rebuild.

### 4.3 Register the peer with bastion

In `config/wireguard.nix`, add to `peers`. Pick an unused address in
`10.100.0.0/24` - `.1` is bastion, and the file lists the rest:

```nix
{
  privateIP = "10.100.0.102";
  publicKey = "<the public key from 4.1>";
}
```

`hosts/bastion/wireguard.nix` turns that list into `allowedIPs` entries
automatically, so bastion needs no other change.

### 4.4 Configure the peer

NixOS, as `hosts/newhost/wireguard.nix`:

```nix
{ config, wireguard, ... }:
{
  sops.secrets.newhost_private_key = {
    sopsFile = ./secrets/wg-newhost-key.enc;
    format = "json";
    key = "private";
    mode = "0400";
  };

  networking.wireguard.interfaces.wg0 = {
    ips = [ "10.100.0.102/24" ];
    privateKeyFile = config.sops.secrets.newhost_private_key.path;

    peers = [
      {
        name = "bastion";
        publicKey = wireguard.bastion.publicKey;
        # The whole VPN subnet, not just bastion: peers reach each other
        # through it, and bastion forwards in the kernel.
        allowedIPs = [ "10.100.0.0/24" ];
        endpoint = "${wireguard.bastion.publicIP}:51820";
        persistentKeepalive = 25;
      }
    ];
  };
}
```

macOS is the same shape but uses `networking.wg-quick.interfaces.wg0` with
`address = [ "10.100.0.102/24" ]` instead of `ips`. See
`hosts/mucie/wireguard.nix`.

Either way the host's `default.nix` has to pass `wireguard` down and import
the file:

```nix
let
  wireguard = import ../../config/wireguard.nix;
in
{
  _module.args = { inherit wireguard; };
  imports = [ ./wireguard.nix ];
}
```

### 4.5 Optional: resolve the .internal names

Services on lucie answer to `grafana.internal`, `loki.internal` and friends.
dnsmasq on bastion serves those names over the tunnel; a peer only needs to
send `.internal` queries there.

NixOS peers get this for free if they use bastion as a resolver. On macOS, add
`hosts/newhost/internal.nix` - see `hosts/mucie/internal.nix`, which writes one
file to `/etc/resolver` so only that domain goes to the tunnel and everything
else keeps using the local network's resolver.

---

## 5. Build and deploy

Locally first, so a mistake shows up before it reaches the machine:

```sh
nix flake check .
```

Then on the machine:

```sh
sudo nixos-rebuild switch --flake .#newhost      # NixOS
sudo darwin-rebuild switch --flake .             # macOS
```

Remote NixOS hosts can go through deploy-rs instead, once a `deploy.nodes`
entry exists in `flake.nix` - see the `bastion` entry. It builds locally,
pushes the closure, and rolls back automatically if the machine stops
answering.

---

## 6. Check it

```sh
# secrets decrypted
ls -l ~/.config/aerc/*.password       # home-manager secrets, if the host has them
sudo ls -l /run/secrets/              # system secrets, if any

# wireguard, if joined
sudo wg show                          # a handshake with bastion within ~30s
ping 10.100.0.1
curl -I http://grafana.internal       # if .internal is configured
```

If a secret fails to decrypt, the cause is almost always that the host's key
is not a recipient yet: check `.sops.yaml` names it, and that you re-ran
`sops updatekeys` afterwards from a machine that could already read the file.

---

## What a new host does not need

- **A copy of any private key.** Both key kinds are generated on the machine
  or already exist there. Copying one defeats the point of per-host keys.
- **Its own home-manager modules.** They come from the distro. Per-host tweaks
  go in `hosts/newhost/default.nix`, like the `programs.mcp` toggles in
  `hosts/mucie/default.nix`.
- **A wireguard entry**, unless it needs to reach lucie's internal services or
  be reachable from the other peers.
