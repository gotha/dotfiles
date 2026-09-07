# cachix.hgeorgiev.com

A private nix binary cache. Reading it needs credentials; the store paths are
signed, so a client verifies what it downloads whatever route it arrived by.

## Credentials

Ask me for credentials.

Create netrc file like `/var/secrets/netrc` with `0600` permissions.

```
machine cachix.hgeorgiev.com
  login <username>
  password <password>
```

## Point nix at it

```nix
nix.settings = {
  extra-substituters = [ "https://cachix.hgeorgiev.com" ];
  extra-trusted-public-keys = [
    "cachix.hgeorgiev.com-1:QbpZajSH6nnVlWmwZaltj8oY+oNN64P1H/jenxjnHuk="
  ];
  netrc-file = "/var/secrets/netrc";
};
```

The same on NixOS and nix-darwin. `extra-` rather than `substituters` and
`trusted-public-keys`, which replace the defaults outright and would drop
cache.nixos.org.

Settings only take effect once the daemon restarts, which `nixos-rebuild` and
`darwin-rebuild` do for you.

## Check it

```sh
curl -s --netrc-file /var/secrets/netrc https://cachix.hgeorgiev.com/nix-cache-info
```

`StoreDir: /nix/store` means credentials, TLS and the proxy are all fine. The
same request without `--netrc-file` should return 401 - worth doing once, since
it is the only quick confirmation that the cache is not open to everyone.

To see it actually serving a build rather than merely answering:

```sh
nix build --print-build-logs .#something
```

Substituted paths are logged as `copying path ... from
'https://cachix.hgeorgiev.com'`.

## Putting things in it

The cache serves lucie's store, so whatever is built there is available with no
further step. From another machine:

```sh
nix copy --to ssh://10.100.0.100 /nix/store/...
```

Reading is public, given the credentials. Writing is not: it goes to lucie
directly and needs both the WireGuard tunnel and ssh access, because lucie has
no public address.
