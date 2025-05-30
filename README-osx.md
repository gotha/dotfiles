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

get the config

```sh
git clone https://github.com/gotha/dotfiles.git && cd dotfiles
```

backup config:

```sh
sudo mv /etc/nix/nix.conf /etc/nix/nix.conf.before-nix-darwin
```

apply:

```sh
nix --extra-experimental-features "nix-command flakes" run nix-darwin -- switch --flake .config/nix
```

then after each change

```sh
sudo nix run nix-darwin -- switch --flake .config/nix
```

to update the flake:

```sh
nix flake update --flake .config/nix
```


## install dotfiles as per usual

look at the [README](./README.md) for instructions on installing the dotfiles
