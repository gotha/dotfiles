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

Follow the official instructions, but it should be something like:

```sh
parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart root ext4 512MB -8GB
parted /dev/sda -- mkpart swap linux-swap -8GB 100%
parted /dev/sda -- mkpart ESP fat32 1MB 512MB
parted /dev/sda -- set 3 esp on

```

Most importantly, you must set the correct labels like:

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
mount /dev/disk/by-label/nixos /mnt

mkdir -p /mnt/boot
mount -o umask=077 /dev/disk/by-label/boot /mnt/boot

swapon /dev/sda2

nixos-install --flake .#lucie
```

post-install config

```sh
nixos-enter --root /mnt -c 'passwd root'
exit
reboot
```

## Apply on a linux system

```sh
nixos-rebuild switch --flake .
```
