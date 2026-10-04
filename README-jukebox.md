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

## The appliance key

Secrets that every appliance may read live in `secrets/appliance/` - today just
`home-wifi.enc.env`, the house wifi password - and are decrypted with one
shared age key, the *appliance key*. Its private half is in this repo at
`secrets/keys/appliance.agekey.enc`, readable by the two workstations and by
breakglass, and `.sops.yaml` makes it a recipient on that directory and nothing
outside it. A machine without the key still boots; it just comes up with no
secrets, which for pizzie means no wifi.

Why one shared key rather than each machine's own: `sshd-keygen.service`
creates a host's ssh key when sshd first starts, long after
`sops-install-secrets` has run during activation, so a freshly written card
cannot decrypt anything on the boot where it matters - and an ssh-derived
identity changes on every reflash, which would mean `sops updatekeys` after
each one. A key minted ahead of time has neither problem, and one key copied to
every appliance means a second box needs no change to `.sops.yaml` at all.

The cost is that many machines hold the same copy, so a single lost SD card
means rotating the key and reseeding every other appliance. That is exactly why
its reach stops at `secrets/appliance/`: putting a file in there is the decision
to share it with every appliance, and the directory boundary makes that decision
visible instead of buried in a regex. Anything one machine should keep to itself
belongs in `hosts/<name>/secrets/` - see "A key of its own" below.

### Put it on a machine

It goes to `/var/lib/sops-nix/key.txt`, mode 0600, root-owned, which is where
`sops.age.keyFile` in `hosts/pizzie/default.nix` points. That option is typed
`pathNotInStore`, so sops-nix refuses a key smuggled in through the image -
this file is the only way in. Two routes to it.

**Onto a card, before first boot.** After `dd`, with the card still in the
reader:

```sh
# dd's close triggers udev's own partition rescan; this waits for the by-label
# link it creates. `blockdev --rereadpt /dev/sdX` forces the rescan if the link
# never shows up - partprobe's job, without needing parted.
sudo udevadm settle
sudo mkdir -p /mnt/card
sudo mount /dev/disk/by-label/NIXOS_SD /mnt/card

sudo install -D -m 0600 -o root -g root /dev/null /mnt/card/var/lib/sops-nix/key.txt
sops -d secrets/keys/appliance.agekey.enc \
  | sudo tee /mnt/card/var/lib/sops-nix/key.txt > /dev/null

sudo umount /mnt/card
sync
```

`install` runs first so the file already exists at 0600 before any key material
lands in it. macOS cannot mount the ext4 root, so a card written there is
seeded from a Linux box, or booted wired once and done the other way:

**Onto a machine already running**, over ssh:

```sh
sops -d secrets/keys/appliance.agekey.enc \
  | ssh root@pizzie 'install -D -m 0600 -o root -g root /dev/stdin /var/lib/sops-nix/key.txt'
ssh root@pizzie /run/current-system/bin/switch-to-configuration switch
```

That second line re-runs activation, which is what installs the secrets; a
reboot does the same thing.

Either way, confirm the key actually opens the secret before trusting a card to
it. This hands sops nothing but the appliance key, so a pass means the card
needs nothing else:

```sh
SOPS_AGE_KEY="$(sops -d secrets/keys/appliance.agekey.enc | grep AGE-SECRET-KEY)" \
  sops -d secrets/appliance/home-wifi.enc.env
```

Whoever holds a card can read the key on it, and so the wifi password. That is
the same boundary as the card itself, which carries the whole root filesystem.

### A key of its own

When a machine needs a secret the rest of the fleet must not read, give it a
second identity rather than widening the appliance key's reach:

```sh
nix shell nixpkgs#age -c age-keygen -o /tmp/vinnie.agekey
grep '# public key' /tmp/vinnie.agekey          # the recipient to add below
sops -e --filename-override secrets/keys/vinnie.agekey.enc /tmp/vinnie.agekey \
  > secrets/keys/vinnie.agekey.enc
shred -u /tmp/vinnie.agekey
```

Same shape as the appliance key: the cleartext exists only long enough to be
encrypted, and `^secrets/keys/` keeps the result readable by the workstations
and breakglass alone. Add the public half to `.sops.yaml` as `&host_vinnie`,
give it a `hosts/vinnie/secrets/` rule listing that key and `*breakglass`,
`sops updatekeys` the files under it, then append the private half to that
machine's `/var/lib/sops-nix/key.txt`. An age identity file may hold several
keys and sops tries all of them, so the appliance key keeps working beside it:

```sh
sops -d secrets/keys/appliance.agekey.enc  > key.txt
sops -d secrets/keys/vinnie.agekey.enc    >> key.txt
```

## First boot

Put it in the Pi, HDMI to the TV. A card carrying the appliance key joins the
wifi by itself, so the cable is optional. Without that key there is no keyboard
on this thing and no way in before it has an address, so that first boot has to
be **wired to the router**.

Kodi comes up on tty1 by itself. To put an unseeded card on wifi, or to move
a seeded one to a different network:

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



```
sudo nix build .#nixosConfigurations.pizzie.config.system.build.toplevel \
    --out-link /nix/var/nix/gcroots/pizzie
```

```
  sudo dd if=/nix/var/nix/gcroots/pizzie-sd.img \
    of=/dev/disk/by-id/usb-Generic_MassStorageClass_000000001538-0:1 \
    bs=4M conv=fsync status=progress
```
  One thing to do before anything else touches the store, now that the kernel actually exists — the result symlink is its only GC root:

  sudo nix build .#nixosConfigurations.pizzie.config.system.build.toplevel \
    --out-link /nix/var/nix/gcroots/pizzie



---------------------

# 1. Build the image (a different attribute from the closure above)
nix build .#packages.aarch64-linux.pizzie-sd
ls -lh result/sd-image/pizzie-sd.img

# 2. Plug the reader in and confirm which device it is
lsblk -o NAME,SIZE,TRAN,RM,LABEL
ls -l /dev/disk/by-id/ | grep MassStorage

# 3. Write it
sudo dd if=result/sd-image/pizzie-sd.img \
  of=/dev/sdd \
  bs=4M conv=fsync status=progress

# 4. Seed the key, or the Pi boots with no wifi
sudo udevadm settle
sudo mkdir -p /mnt/card
sudo mount /dev/disk/by-label/NIXOS_SD /mnt/card

sops decrypt ./secrets/keys/appliance.agekey.enc > /tmp/appliance.agekey
sudo install -D -m 0600 -o root -g root \
  /tmp/appliance.agekey /mnt/card/var/lib/sops-nix/key.txt
sudo umount /mnt/card
sync

-------------------

● It was these two commands — age isn't installed, so they run straight from nixpkgs:

  sudo nix shell nixpkgs#age -c age-keygen -o /var/secrets/pizzie-sops.agekey   # mint
  sudo nix shell nixpkgs#age -c age-keygen -y /var/secrets/pizzie-sops.agekey   # print public half

  -o writes a new X25519 identity at mode 0600 and prints Public key: age1…; -y re-derives that public half from the
  file later. You don't strictly need -y — the file carries it in a comment:

  # created: 2026-10-04T12:53:19+03:00
  # public key: age1jjcsfegc9u3dtgzk6sqd4nuajsetnfu7z8vhhsrkzy5ajjxwscrsfdw0nm
  AGE-SECRET-KEY-1…          ← line 3, the part that matters

  so sudo grep '# public key' /var/secrets/<host>-sops.agekey gets you the recipient with no tooling at all.

  For another device — say vinnie

  # 1. mint it, outside the repo
  sudo nix shell nixpkgs#age -c age-keygen -o /var/secrets/vinnie-sops.agekey
  sudo nix shell nixpkgs#age -c age-keygen -y /var/secrets/vinnie-sops.agekey

  2. .sops.yaml, under the # Hosts block: - &host_vinnie age1…, then add *host_vinnie to the key_groups of every rule
     whose secrets it reads — ^secrets/ for the house wifi, plus a hosts/vinnie/secrets/ rule if it gets private ones.
  3. Re-encrypt to the new recipient. Per file, not per rule — sops only rewrites what you name:

  sops updatekeys secrets/home-wifi.enc.env

  4. In hosts/vinnie/default.nix:

  sops.age = {
    keyFile = "/var/lib/sops-nix/key.txt";
    sshKeyPaths = [ ];
  };

  5. Seed the card with the same install -D line, pointing at vinnie-sops.agekey.

