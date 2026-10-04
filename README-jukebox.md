# jukebox

A NixOS appliance with Kodi.
Currently used only on `pizzie` - Raspberry Pi 3B.

---

## Build the image

The Pi is aarch64 and the image has to be built on Linux, so this happens on
lucie, which reaches aarch64 through `boot.binfmt.emulatedSystems`
(`hosts/lucie/default.nix:43`).

```sh
nix build .#packages.aarch64-linux.pizzie-sd
ls -lh result/sd-image/pizzie-sd.img
```

Note: We need vendor kernel because of the `bcm2835-codec` for hardware decoding of h.264.

Compilation takes couple of hours (like 12 on lucie). To make sure the compiled
kernel is not garbage collected:

```sh
sudo nix build .#nixosConfigurations.pizzie.config.system.build.toplevel \
    --out-link /nix/var/nix/gcroots/pizzie
```

## Write it to a card

```sh
# Check the device name twice - dd to the wrong one eats a disk.
lsblk
sudo dd if=result/sd-image/pizzie-sd.img of=/dev/sdX bs=4M conv=fsync status=progress
```

The root partition grows to fill the card on first boot.

## The appliance key

To connect to the wifi ./secrets/appliance/home-wifi.enc.env is used.
You need to copy the key on the SD card so the Pi can decrypt the secret.

```sh
sudo udevadm settle
sudo mkdir -p /mnt/card
sudo mount /dev/disk/by-label/NIXOS_SD /mnt/card

sops decrypt ./secrets/keys/appliance.agekey.enc > /tmp/appliance.agekey
sudo install -D -m 0600 -o root -g root \
  /tmp/appliance.agekey /mnt/card/var/lib/sops-nix/key.txt
sudo umount /mnt/card
sync
```

## Boot

You should be able to boot the PI and it will automatically connect to the Wifi network.


## Update

To update the Pi over the network:

```sh
nix run github:serokell/deploy-rs -- .#pizzie
```
