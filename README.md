# My dotfiles

## Install

```sh
git clone https://github.com/gotha/dotfiles.git && cd dotfiles
```

Depending on your OS follow one of these guides:
- [NixOS](./README-nixos.md)
- [OS X](./README-darwin.md)


### neovim

Plugins will be automatically installed by lazy.nvim on first run.

To manually sync plugins:

```sh
nvim +Lazy sync
```

### tmux

Start `tmux` and press `prefix` + `I` (shift + i) to install the required plugins.

or manually:

```sh
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
killall tmux
tmux
~/.tmux/plugins/tpm/bin/install_plugins
```

### Vale

```sh
vale sync
```

to update vale styles

## Deploy remote host

```sh
nix run github:serokell/deploy-rs -- .#bastion
```

## Install on QEMU

on M processor Mac the distro `devbox-arm` is build instead of `devbox`;

### Build

```sh
nix build .#devbox-qemu
```

### Run

```sh
nix run .#devbox-qemu
```

State lives in `qemu/devbox.qcow2`
```sh
nix run .#devbox-qemu -- --fresh
```

discards the overlay and the EFI variables.


```sh
ssh -p 2222 gotha@localhost
```


### Copy secrets in a fresh VM

```sh
scp -P 2222 ~/.ssh/id_rsa ~/.ssh/id_rsa.pub gotha@localhost:.ssh/
ssh -p 2222 gotha@localhost 'chmod 600 ~/.ssh/id_rsa'
```

```sh
gpg --export-secret-keys 7EFF0CECB200083C60EA2AA2C8DDF8A8BDF70670 \
  | ssh -p 2222 gotha@localhost 'gpg --import'
ssh -p 2222 gotha@localhost '
  chmod 700 ~/.gnupg
  find ~/.gnupg -mindepth 1 -maxdepth 1 -type d -exec chmod 700 {} \;
  systemctl --user restart sops-nix.service
'
```

successful run is the healthy state:

```sh
ssh -p 2222 gotha@localhost '
  systemctl --user status sops-nix.service --no-pager | head -3
  ls ~/.config/sops-nix/secrets/
'
```

## Get ready to contribute

```sh
git remote set-url origin git@github.com:gotha/dotfiles.git
git config --local core.hooksPath .githooks/
```
