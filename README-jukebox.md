# jukebox

A NixOS appliance whose entire user interface is Kodi. No X, no Wayland
compositor, no display manager: `kodi-gbm` renders straight onto KMS, started
by systemd on tty1.

| | |
| --- | --- |
| distro | `distros/jukebox` - board-neutral: Kodi, CEC, networking, ssh |
| host | `hosts/pizzie` - Raspberry Pi 3 Model B, SD card layout, `config.txt` |
| image | `nix build .#packages.aarch64-linux.pizzie-sd` |

The split is the point. Nothing in `distros/jukebox` knows it is running on a
Pi, so the same distro takes an x86 home theatre PC: write a new host with that
machine's `hardware-configuration.nix` and EFI bootloader, and list
`distro.jukebox` for it in `flake.nix`. See `guides/adding-a-host.md`.

---

## Build the image

The Pi is aarch64 and the image has to be built on Linux, so this happens on
lucie, which reaches aarch64 through `boot.binfmt.emulatedSystems`
(`hosts/lucie/default.nix:43`). A Mac cannot build it at all.

```sh
nix build .#packages.aarch64-linux.pizzie-sd
ls -lh result/sd-image/pizzie-sd.img
```

**The first build compiles a kernel under emulation, and that takes hours.**
nixpkgs removed the `linux_rpi*` kernels in September 2026, so the Raspberry Pi
vendor kernel now comes from nixos-hardware, which builds it from
`raspberrypi/linux` - and nothing in cache.nixos.org has it. Every compiler
invocation runs through qemu-user on an x86 host.

It happens once, and building it on lucie is also what publishes it:
`cachix.hgeorgiev.com` serves lucie's store, so the kernel is in the cache the
moment it exists and no other machine ever compiles it. Nothing to push. See
`README-cachix.md`.

Why the vendor kernel rather than mainline: `bcm2835-codec`, the V4L2 interface
to the Pi 3's hardware H.264 decoder, exists only in the Raspberry Pi fork.
Mainline drives HDMI and CEC perfectly well through `vc4`, but leaves video
decoding to four 1.2 GHz A53 cores. To go back to mainline, drop
`boot.kernelPackages` from the `raspberry-pi-3` profile by setting it in
`hosts/pizzie/default.nix`; everything else here is unaffected.

## Write it to a card

The image is uncompressed on purpose (`sdImage.compressImage = false`), so
there is no zstd in the pipe.

```sh
# Linux. Check the device name twice - dd to the wrong one eats a disk.
lsblk
sudo dd if=result/sd-image/pizzie-sd.img of=/dev/sdX bs=4M conv=fsync status=progress

# macOS
diskutil list
diskutil unmountDisk /dev/diskN
sudo dd if=result/sd-image/pizzie-sd.img of=/dev/rdiskN bs=4m
```

The root partition grows to fill the card on first boot.

## First boot

Put it in the Pi, HDMI to the TV, **ethernet to the router**. There is no
keyboard on this thing and no way in before it has an address, so the first
boot is wired even if the plan is wifi.

Kodi comes up on tty1 by itself. To get it onto wifi afterwards:

```sh
ssh gotha@pizzie
nmtui
```

Then `nixos-rebuild switch --flake .#pizzie` on the machine, or push a closure
with deploy-rs once there is a `deploy.nodes.pizzie` entry in `flake.nix`.

## HDMI-CEC

This is the part that makes the TV remote drive Kodi, and it is also the part
most likely to need a nudge from the TV's own settings - every manufacturer
brands CEC differently (Anynet+ on Samsung, Bravia Sync on Sony, Simplink on
LG, Viera Link on Panasonic). Turn it on there first.

The Pi registers a CEC adapter through `vc4`, which `config.txt` enables with
`dtoverlay=vc4-kms-v3d`. It appears to the TV as `Jukebox`
(`hardware.raspberry-pi.configtxt.settings.all.cec_osd_name`).

Three checks, narrowest first:

```sh
# 1. Did the kernel register an adapter at all?
ls -l /dev/cec0
cec-ctl -d /dev/cec0 --show-topology

# 2. Does anything answer on the bus? Lists every CEC device the TV knows.
echo scan | cec-client -s -d 1

# 3. Is Kodi using it? Settings > System > Input > Peripherals > CEC Adapter
journalctl -u kodi | grep -i cec
```

If 1 fails there is no adapter - check that `vc4-kms-v3d` is in
`/boot/firmware/config.txt`. If 1 works and 2 finds nothing, CEC is off on the
TV. If 2 works and 3 does not, it is Kodi's own peripheral settings.

## Day-to-day

```sh
systemctl status kodi
journalctl -u kodi -f
systemctl restart kodi
```

Kodi runs as `gotha`, not a dedicated service user. Worth knowing what that
means: `os/linux/user.nix` puts `gotha` in `wheel` with
`security.sudo.wheelNeedsPassword = false`, so Kodi, every addon it loads, and
anyone who plugs a USB keyboard into the TV, are all one `sudo` from root. Fine
on a home LAN, not fine on a machine anyone else can reach.

`/boot/firmware` is mounted (`nofail`, not the `noauto` that `sd-image.nix`
defaults to) so that `hardware.raspberry-pi.firmware.enable` can rewrite
`config.txt` and U-Boot on every `nixos-rebuild switch`. Without the mount the
activation script skips with a warning and firmware changes silently never land.

## Addons

Python addons install from Kodi's own repository in the UI and work normally.
**Binary addons do not** - Kodi's repository ships them expecting an FHS layout.
Those have to come from `kodiPackages` and be named in the `withPackages` list
in `distros/jukebox/kodi.nix`, which currently holds:

| addon | |
| --- | --- |
| `inputstream-adaptive`, `inputstreamhelper` | DASH and HLS playback, and the helper other addons probe for |
| `keymap` | remap remote buttons from Kodi's UI - the CEC one |
| `upnext` | auto-play the next episode |
| `a4ksubtitles` | subtitle search |
| `youtube`, `sponsorblock` | YouTube, minus the sponsor segments |
| `vfs-sftp` | play media over ssh with nothing mounted |
| `plex-for-kodi` | Plex client |

`youtube` usually wants your own Google API key before sign-in and personal
lists work; that is the addon's own setup, not something this repo can declare.

Deliberately absent: `netflix` is packaged, but it needs the Widevine CDM,
which `inputstreamhelper` has to extract from a ChromeOS image on arm64, and
Widevine on Linux caps at 720p regardless.

## If video stutters

A Pi 3B is a 2016 board with 1 GB of RAM, and this is the first thing to
suspect before anything in this repo. In rough order:

1. `journalctl -u kodi | grep -i -e cma -e 'failed to allocate'`. If the CMA
   pool is exhausted, raise it by adding `cma-256` to the `vc4-kms-v3d` overlay
   in `/boot/firmware/config.txt` by hand and rebooting. If that fixes it,
   fold it into `hardware.raspberry-pi.configtxt.deviceTreeOverlays`.
2. Check Kodi is actually hardware-decoding: Settings > Player > Videos, with
   the settings level on Expert, then watch CPU during playback. Four cores
   pinned means it is decoding in software and the vendor kernel's decoder is
   not being used.
3. H.265 and 4K have no hardware path on this board at all. They will not work
   and no setting changes that.
