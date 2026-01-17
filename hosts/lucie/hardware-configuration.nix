{ config, lib, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  hardware = {
    enableAllFirmware = true;
    enableRedistributableFirmware = true;
    bluetooth = {
      enable = true; # enables support for Bluetooth
      powerOnBoot = true; # powers up the default Bluetooth controller on boot
      settings = {
        Policy = { AutoEnable = true; };
        General = { Experimental = true; };
      };
    };
  };

  boot.initrd.availableKernelModules =
    [ "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];
  boot.blacklistedKernelModules = [ "nouveau" ];

  hardware.graphics.enable = true;

  hardware.nvidia = {
    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
    # of just the bare essentials.
    powerManagement.enable = false;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of
    # supported GPUs is at:
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    # Only available from driver 515.43.04+
    open = true;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.beta;

  };

  hardware.nvidia-container-toolkit.enable = true;

  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  boot.extraModprobeConfig = ''
    options snd_hda_intel power_save=0 power_save_controller=N
    options snd_hda_codec_hdmi enable_silent_stream=1
    options btusb enable_autosuspend=0
  '';

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  # @todo - change name from gotha to variable username
  # Create the mount point directory
  systemd.tmpfiles.rules = [ "d /mnt/storage 0755 gotha gotha -" ];

  # Mount the second hard drive to /mnt/storage
  fileSystems."/mnt/storage" = {
    # Replace with your actual device path (e.g., /dev/sdb1, /dev/nvme1n1p1, etc.)
    device = "/dev/disk/by-uuid/d5d21bfb-758b-494c-8633-f6f067ed90e2";

    # Specify the filesystem type (ext4, ntfs, xfs, btrfs, etc.)
    fsType = "ext4";

    # Mount options
    options = [
      "defaults"
      "nofail" # Don't fail boot if drive is missing
      "user" # Allow users to mount/unmount
      "exec" # Allow execution of binaries
    ];
  };

  fileSystems."/mnt/oldroot" = {
    # Replace with your actual device path (e.g., /dev/sdb1, /dev/nvme1n1p1, etc.)
    device = "/dev/disk/by-uuid/d60638da-35b9-4793-9bb5-db1ee4781f95";

    # Specify the filesystem type (ext4, ntfs, xfs, btrfs, etc.)
    fsType = "ext4";

    # Mount options
    options = [
      "defaults"
      "nofail" # Don't fail boot if drive is missing
      "user" # Allow users to mount/unmount
      "exec" # Allow execution of binaries
    ];
  };

  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 65536; # Size in MB (64 GB)
  }];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp5s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;
}
