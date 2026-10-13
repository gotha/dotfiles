# One USB installer for every x86 Linux host here, carrying their closures so
# install-host needs no network.
{
  lib,
  pkgs,
  installerHosts,
  ...
}:
let
  # Read from each host's own fileSystems, so a changed UUID cannot drift.
  label = dev: lib.removePrefix "/dev/disk/by-label/" dev;
  uuid = dev: lib.removePrefix "/dev/disk/by-uuid/" dev;

  ext4Flag =
    name: dev:
    if lib.hasPrefix "/dev/disk/by-label/" dev then
      "-L ${label dev}"
    else if lib.hasPrefix "/dev/disk/by-uuid/" dev then
      "-U ${uuid dev}"
    else
      throw "installer: ${name} roots on ${dev}, which is neither by-label nor by-uuid";

  hostBranch =
    name: cfg:
    let
      c = cfg.config;
      root = c.fileSystems."/";
      esp = c.fileSystems."/boot" or null;
      efi = c.boot.loader.systemd-boot.enable;
      grubDevices =
        c.boot.loader.grub.devices
        ++ lib.optional (c.boot.loader.grub.device != "") c.boot.loader.grub.device;
    in
    ''
      ${name})
        system=${c.system.build.toplevel}
        root_flag="${ext4Flag name root.device}"
        root_dev=${root.device}
        esp_label=${if esp == null then "" else label esp.device}
        esp_dev=${if esp == null then "" else esp.device}
        boot=${if efi then "efi" else "bios"}
        grub_devices="${lib.concatStringsSep " " grubDevices}"
        ;;
    '';

  install-host = pkgs.writeShellApplication {
    name = "install-host";
    runtimeInputs = with pkgs; [
      coreutils
      dosfstools
      e2fsprogs
      gptfdisk
      nixos-install-tools
      util-linux
    ];
    text = ''
      usage() {
        echo "usage: install-host <host> <disk>"
        echo "  hosts: ${lib.concatStringsSep " " (lib.attrNames installerHosts)}"
        echo "  e.g.   install-host thucie /dev/sda"
      }

      [ $# -eq 2 ] || { usage; exit 1; }
      host=$1
      disk=$2

      case "$host" in
      ${lib.concatStrings (lib.mapAttrsToList hostBranch installerHosts)}
      *)
        echo "unknown host: $host"
        usage
        exit 1
        ;;
      esac

      [ -b "$disk" ] || { echo "$disk is not a block device"; exit 1; }

      # A BIOS host's bootloader is written to the device its config names, not
      # to the disk given here, so a mismatch installs a system that cannot
      # boot. Refuse rather than discover that after the reboot.
      if [ "$boot" = bios ]; then
        case " $grub_devices " in
          *" $disk "*) ;;
          *)
            echo "ERROR: $host installs GRUB to$grub_devices, not $disk."
            echo "Change boot.loader.grub in its config, or install to that disk."
            exit 1
            ;;
        esac
      fi

      echo "About to ERASE $disk and install $host:"
      lsblk -o NAME,SIZE,MODEL,LABEL "$disk" || true
      printf 'Type the disk path to confirm: '
      read -r confirm
      [ "$confirm" = "$disk" ] || { echo "aborted"; exit 1; }

      wipefs -a "$disk"
      if [ "$boot" = efi ]; then
        sgdisk -Z -n 1:0:+512M -t 1:ef00 -n 2:0:0 -t 2:8300 "$disk"
      else
        # 1 MiB ef02: GRUB's i386-pc core.img has nowhere to live on a GPT disk
        # without it.
        sgdisk -Z -n 1:0:+1M -t 1:ef02 -n 2:0:0 -t 2:8300 "$disk"
      fi
      udevadm settle

      # /dev/sda2 but /dev/nvme0n1p2.
      part() { if [ -b "$disk$1" ]; then echo "$disk$1"; else echo "''${disk}p$1"; fi; }

      # shellcheck disable=SC2086
      mkfs.ext4 -F $root_flag "$(part 2)"
      [ -z "$esp_dev" ] || mkfs.vfat -F 32 -n "$esp_label" "$(part 1)"
      udevadm settle

      mount "$root_dev" /mnt
      if [ -n "$esp_dev" ]; then
        mkdir -p /mnt/boot
        mount "$esp_dev" /mnt/boot
      fi

      nixos-install --system "$system" --no-root-passwd

      echo
      echo "Installed $host. Its secrets will not decrypt until the new host key"
      echo "is a recipient: ssh-to-age the fresh /etc/ssh/ssh_host_ed25519_key.pub,"
      echo "put it in .sops.yaml, then sops updatekeys the files it covers."
    '';
  };
in
{
  isoImage = {
    storeContents = lib.mapAttrsToList (_: cfg: cfg.config.system.build.toplevel) installerHosts;
    # iso-image.nix defines this without mkDefault, hence the force.
    isoBaseName = lib.mkForce "hatchery-installer";
    # The module default is level 19, which costs far more time than the bytes
    # it saves on a closure this size.
    squashfsCompression = "zstd -Xcompression-level 6";
  };

  environment.systemPackages = [ install-host ];
}
