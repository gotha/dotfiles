# Self-contained UEFI disk image, built with systemd-repart.
#
# Everything else in nixpkgs that produces a bootable image - system.build.
# images.qemu, and the systemImage behind virtualisation.useBootLoader - goes
# through nixos/lib/make-disk-image.nix, which copies the closure in with
# cptofs (the lkl ext4 tool). cptofs spins forever on a closure this size, so
# neither is usable here. systemd-repart writes the filesystem directly and
# does not involve cptofs at all.
#
# The result is a single .raw that carries its own store, so unlike
# system.build.vm it does not mount the host's /nix/store and will boot on any
# machine with a UEFI-capable qemu.
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
let
  efiArch = pkgs.stdenv.hostPlatform.efiArch;
  closure = pkgs.closureInfo { rootPaths = [ config.system.build.toplevel ]; };
in
{
  imports = [ "${modulesPath}/image/repart.nix" ];

  # The image boots a UKI that systemd-boot finds in the ESP, so there is no
  # GRUB and nothing installs a bootloader into the running system. grub
  # defaults to enabled, hence the explicit disable.
  boot.loader.grub.enable = false;

  system.image.id = "devbox";
  system.image.version = "1";

  # repart labels the root partition, so address it that way rather than by
  # the filesystem label hosts/qemu1 uses.
  fileSystems."/" = lib.mkForce {
    device = "/dev/disk/by-partlabel/root";
    fsType = "ext4";
  };

  image.repart = {
    name = "devbox";
    # OVMF cannot read the 4096-byte sectors repart defaults to.
    sectorSize = 512;
    partitions = {
      "esp" = {
        contents = {
          "/EFI/BOOT/BOOT${lib.toUpper efiArch}.EFI".source =
            "${pkgs.systemd}/lib/systemd/boot/efi/systemd-boot${efiArch}.efi";
          "/EFI/Linux/${config.system.boot.loader.ukiFile}".source =
            "${config.system.build.uki}/${config.system.boot.loader.ukiFile}";
        };
        repartConfig = {
          Type = "esp";
          Format = "vfat";
          # The UKI bundles kernel and initrd, and this initrd is not small.
          SizeMinBytes = "512M";
        };
      };
      "root" = {
        storePaths = [ config.system.build.toplevel ];
        contents = {
          "/nix-path-registration".source = "${closure}/registration";
        };
        repartConfig = {
          Type = "root";
          Format = "ext4";
          Label = "root";
          # Size the partition to the closure instead of a fixed guess.
          Minimize = "guess";
        };
      };
    };
  };

  # repart writes the store paths into the image but never populates the Nix
  # database, so `nix-store --realise` fails on paths that are physically
  # present. That is what makes the nixpkgs example an "appliance" image, and
  # here it broke home-manager: activation calls nix-store --realise on its own
  # generation, gets an error, and aborts before writing ~/.config - leaving
  # sway to fall back to its stock config with no wallpaper and no dotfiles.
  #
  # Register the closure on first boot, the way the sd-card and ISO images do.
  # postBootCommands runs in stage 2 before systemd starts, so this lands well
  # before home-manager-<user>.service.
  boot.postBootCommands = lib.mkAfter ''
    if [ -f /nix-path-registration ]; then
      ${lib.getExe' config.nix.package.out "nix-store"} --load-db < /nix-path-registration
      rm -f /nix-path-registration
      # nixos-rebuild also wants a system profile and an /etc/NIXOS tag.
      touch /etc/NIXOS
      ${lib.getExe' config.nix.package.out "nix-env"} -p /nix/var/nix/profiles/system --set /run/current-system
    fi
  '';
}
