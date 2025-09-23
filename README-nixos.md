# NixOS

## Install via NixOS installer

Follow the install guide:
 - [online](https://nixos.org/manual/nixos/stable/#sec-installation-manual)
 - or in the terminal `nixos-help`

### Configure installer

Connect to wifi if needed

```sh
sudo systemctl start wpa_supplicant
sudo wpa_cli
> add_network
> set_network 0 ssid "myhomenetwork"
> set_network 0 psk "mypassword"
> enable_network 0
```

### Partition

Follow the official instructions, Importantly, you must set the correct labels like:

```sh
mkfs.ext4 -L nixos /dev/sda1
mkswap -L swap /dev/sda2
# if uefi
mkfs.fat -F 32 -n boot /dev/sda3
```

### Install

Get the code:

```sh
git clone https://github.com/gotha/dotfiles.git /tmp/dotfiles
cd /tmp/dotfiles
```

Enable flakes for the installer if needed

```sh
export NIX_CONFIG="experimental-features = nix-command flakes"
```

Install

```sh
sudo nixos-install --flake .#lucie
```

post-install config

```sh
sudo nixos-enter --root /mnt
passwd root
exit
reboot
```

## Apply on a linux system

```sh
nixos-rebuild switch --flake .
```
