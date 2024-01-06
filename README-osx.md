# OSX

## install tools

```sh
xcode-select --install
```

## install Nix:

```sh
sh <(curl -L https://nixos.org/nix/install)
```

## install homebrew:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## Prepare config
set computer name if needed

```sh
sudo scutil --set ComputerName platypus
sudo scutil --set LocalHostName platypus
sudo reboot
```

remove old config files if needed

```sh
sudo mv /etc/shells /etc/shells.before-nix-darwin
```

## Build nix flake

```sh
cd ~/.config/nix
nix --extra-experimental-features "nix-command flakes" build .#darwinConfigurations.platypus.system

./result/sw/bin/darwin-rebuild switch --flake  .
```

from that point on, after every change run):

```sh
darwin-rebuild switch --flake ~/.config/nix/
```
