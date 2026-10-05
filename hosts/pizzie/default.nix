# pizzie: a Raspberry Pi 3 Model B booting jukebox off an SD card.
#
# Everything that knows this is a Pi lives here; distros/jukebox knows nothing
# about one. The nixos-hardware raspberry-pi-3 profile, wired in from
# flake.nix, brings the vendor kernel, the config.txt generator and the
# firmware-partition installer. This file says how the card is laid out and
# what happens on the HDMI side of it.
{
  config,
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    # Builds config.system.build.sdImage: an MBR card with a FAT firmware
    # partition and an ext4 root that grows to fill the card on first boot.
    # This module alone, not sd-image-aarch64.nix, which also pulls in
    # profiles/base.nix and writes its own populateFirmwareCommands - the
    # raspberry-pi-3 profile covers both, and mkForces that second one back
    # out of the way.
    "${modulesPath}/installer/sd-card/sd-image.nix"
  ];

  networking.hostName = "pizzie";

  # The appliance key, written onto the card by hand. README-jukebox.md.
  sops.age = {
    keyFile = "/var/lib/sops-nix/key.txt";
    sshKeyPaths = [ ]; # the default is a host key, absent on a fresh card
  };

  sops.secrets."home-wifi" = {
    sopsFile = ../../secrets/appliance/home-wifi.enc.env;
    format = "dotenv";
    key = ""; # the whole file: NetworkManager reads it as an EnvironmentFile
  };

  # envsubst fills these in at boot, so neither value is in the store copy.
  networking.networkmanager.ensureProfiles = {
    environmentFiles = [ config.sops.secrets."home-wifi".path ];
    profiles.home-wifi = {
      connection = {
        id = "home-wifi";
        type = "wifi";
      };
      wifi = {
        mode = "infrastructure";
        ssid = "$HOME_WIFI_SSID";
      };
      wifi-security = {
        key-mgmt = "wpa-psk";
        psk = "$HOME_WIFI_PSK";
      };
      ipv4.method = "auto";
      ipv6.method = "auto";
    };
  };

  hardware.raspberry-pi.firmware = {
    # Repopulate /boot/firmware on every nixos-rebuild switch, so a change to
    # config.txt or a U-Boot bump reaches the card without reflashing it.
    enable = true;
    # The GPU firmware loads u-boot.bin, which then reads extlinux.conf. That
    # indirection is what gives a Pi the NixOS generation menu and rollback;
    # having the firmware load the kernel directly would lose both.
    uboot.enable = true;
  };

  # sd-image.nix mounts the firmware partition noauto, on the grounds that
  # nothing needs it once the kernel is up. The activation script enabled above
  # does: it checks `mountpoint` first and otherwise skips with a warning, so
  # left as noauto it would quietly never update config.txt.
  fileSystems."/boot/firmware".options = lib.mkForce [ "nofail" ];

  # The USB disk behind the TV. Automounted, so Kodi boots without it.
  boot.supportedFilesystems.hfsplus = true;

  fileSystems."/media/bkp" = {
    device = "/dev/disk/by-uuid/4c714431-071c-3826-aead-5995982f98a7";
    fsType = "hfsplus";
    noCheck = true; # no fsck.hfsplus here, and systemd-fsck@ failing kills the mount
    options = [
      "noauto"
      "x-systemd.automount"
      "x-systemd.device-timeout=10"

      # HFS+ has no ownership this driver trusts; Kodi's user is in users.
      "gid=100"
      "umask=002"
      "nls=utf8"

      # ponytail: rw on a journaled volume needs force - the driver cannot keep
      # the journal, so an unclean unplug wants a Mac to repair. Drop both after
      # `diskutil disableJournal`, or reformat exFAT.
      "force"
      "rw"
    ];
  };

  hardware.raspberry-pi.configtxt.settings.all = {
    # The name the TV shows for this input in its own menus and on the CEC bus.
    cec_osd_name = "Jukebox";

    # 1.2 A across the USB ports instead of 600 mA, for the disk's spin-up
    # surge - which browns out the 5 V rail and fails the SD read at boot.
    max_usb_current = 1;
  };

  boot = {
    # Otherwise the analog card takes ALSA 0 from vc4hdmi and Kodi's "Default"
    # misses the TV. dtparam=audio=off does not do it: snd_bcm2835 is built
    # into the vendor kernel and registers through the mailbox, with no DT node.
    kernelParams = [ "snd_bcm2835.enable_headphones=0" ];

    # Each generation keeps a kernel and an initrd on the ext4 root. The card is
    # small and the firmware partition is smaller, so keep fewer around than the
    # 10 that os/nixos/bootloader.nix allows the EFI hosts.
    loader.generic-extlinux-compatible.configurationLimit = 5;
  };

  sdImage = {
    # Uncompressed, so flashing is `dd` with no zstd in the pipe. Costs
    # transfer size, which only matters if the image leaves the machine that
    # built it.
    compressImage = false;
    # Default is 30 MB, sized in 2019 for firmware plus U-Boot. nixos-hardware
    # stages every vendor DTB and the whole overlays directory alongside them,
    # which is a good deal more than that was measured against.
    firmwareSize = 128;

    # The root half of the same job: write the extlinux.conf that U-Boot reads,
    # plus the kernel and initrd it points at. sd-image.nix declares this
    # option without a default, and the raspberry-pi-3 profile only fills in
    # the firmware side, so an image build fails on the missing value without
    # it. Same two lines sd-image-aarch64.nix uses.
    populateRootCommands = ''
      mkdir -p ./files/boot
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
    '';
  };

  # Lands as pizzie-sd.img rather than nixos-sd-image-<version>-aarch64.img.
  image.baseName = "pizzie-sd";
}
