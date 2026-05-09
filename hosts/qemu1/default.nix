_: {
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  boot.loader.grub = {
    enable = true;
    device = "/dev/vda"; # or appropriate device
  };
}
