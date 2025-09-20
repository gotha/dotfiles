
```sh
nix build .#nixosConfigurations.lucie.config.system.build.toplevel
```


osx:

```sh
sudo nix run nix-darwin -- switch --flake ./nix
```

