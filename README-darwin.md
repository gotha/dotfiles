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
sudo echo "homebrew needs sudo session" && \
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```


## apply nix config

backup config:

```sh
sudo mv /etc/nix/nix.conf /etc/nix/nix.conf.before-nix-darwin
```

apply:

```sh
nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake .
```

then after each change

```sh
sudo darwin-rebuild switch --flake .
```

to update the flake:

```sh
nix flake update --flake .
```

to update single input of a flake

```sh
nix flake update gotha
```
