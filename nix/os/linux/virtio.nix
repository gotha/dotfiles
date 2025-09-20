{ ... }: {
  boot.initrd.availableKernelModules =
    [ "virtio_pci" "virtio_blk" "virtio_scsi" "virtio_console" "virtio_net" ];
}
