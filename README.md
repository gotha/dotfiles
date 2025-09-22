# My dotfiles

## Install

```sh
git clone https://github.com/gotha/dotfiles.git && cd dotfiles
```

Depending on your OS follow one of these guides:
- [NixOS](./README-nixos.md)
- [OS X](./README-darwin.md)


### neovim

Install all plugins

```sh
nvim +PackerSync
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

## Install on QEMU

### Generate and boot disk image

```sh
nix build .#packages.x86_64-linux.devbox-qemu
./run-qemu.sh
```

### Update configuration over ssh

```sh
nix run .#deploy-devbox-qemu
```

## Get ready to contribute

```sh
git remote set-url origin git@github.com:gotha/dotfiles.git
```
