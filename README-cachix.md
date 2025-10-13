# cachix.hgeorgiev.com

## Serve

to host cachix.hgeorgiev.com make sure that nix-serve is enabled 

```nix
services = {
    nix-serve = {
      enable = true;
      package = pkgs.nix-serve-ng;
      secretKeyFile = "/var/secrets/cache-private-key.pem";
      openFirewall = true;
    };
};
```

and generate key

```sh
mkdir -p /var/secrets
cd /var/secrets
nix-store --generate-binary-cache-key cachix.hgeorgiev.com-1 cache-private-key.pem cache-public-key.pem
```

## Use

on the client machine:

```sh
touch /var/secrets/cachix.netrc
```

put it it:

```
machine cachix.hgeorgiev.com
  login supers3cretUser
  password supers3cretPass
```

and enable with


```nix
nix.settings = {
  substituters = [ "http://cachix.hgeorgiev.com" ];
  trusted-public-keys =
    [ "cachix.hgeorgiev.com-1:QbpZajSH6nnVlWmwZaltj8oY+oNN64P1H/jenxjnHuk=" ];
  netrc-file = "/var/secrets/netrc";
};
```

test with

```sh
curl -u user:pass http://cachix.hgeorgiev.com/nix-cache-info
```
