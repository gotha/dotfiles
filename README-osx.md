# OSX

## Prepare

### set computer name if needed

```sh
sudo scutil --set ComputerName platypus
sudo scutil --set LocalHostName platypus
sudo reboot
```

### remove old config files (if needed)

```sh
sudo mv /etc/shells /etc/shells.before-nix-darwin
sudo mv /etc/nix/nix.conf /etc/nix/nix.conf.before-nix-darwin
```


## install tools

```sh
xcode-select --install
softwareupdate --install-rosetta --agree-to-license
```

## install Nix:

[Determinate Systems' installer](https://github.com/DeterminateSystems/nix-installer?tab=readme-ov-file):

```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
  sh -s -- install
```

## install homebrew:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```


## apply nix config

```sh
nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake .config/nix
```

## add nix binaries to path

```sh
export PATH="/run/current-system/sw/bin:$PATH"
```

## install dotfiles as per usual

look at the [README](./README.md) for instructions on installing the dotfiles
