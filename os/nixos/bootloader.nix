{ ... }: {
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.grub.configurationLimit = 10;
}
