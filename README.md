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

### Build and boot a VM

```sh
nix run .#devbox-qemu
```

Builds a self-contained UEFI disk image and boots it. The host's Nix store is
used to *build* the image but is not mounted into the running VM - the image
carries its own store on its own partition - so the `.raw` can be copied to any
machine with a UEFI-capable qemu and booted there.

State lives in `qemu/devbox.qcow2`, a thin overlay backed by the image, so runs
are cheap and the image itself stays untouched. `nix run .#devbox-qemu -- --fresh`
discards the overlay and the EFI variables.

An overlay is only valid for the image it was created from, so when the image
changes the old one is detected and recreated automatically - the VM's state is
lost at that point, which is unavoidable since the overlay refers to blocks of
the previous image.

Log in as `gotha`, or `ssh -p 2222 gotha@localhost`.

To build just the image, e.g. to copy it elsewhere:

```sh
nix build .#devbox-qemu     # -> result/devbox_1.raw
```

The image is built with `systemd-repart` (`os/linux/repart-image.nix`) rather
than `nixos/lib/make-disk-image.nix`, which every stock image path uses and
which copies the closure with `cptofs` - that spins forever on a closure this
size. Note the closure is ~29 GiB, so the image is ~47 GB.

## Get ready to contribute

```sh
git remote set-url origin git@github.com:gotha/dotfiles.git
git config --local core.hooksPath .githooks/
```
