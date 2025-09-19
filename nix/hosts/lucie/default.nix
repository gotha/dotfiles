{ ... }: {

  imports = [ ./hardware-configuration.nix ../../os/linux/efi.nix ];

  networking.hostName = "lucie";

  services = { xserver.videoDrivers = [ "nvidia" ]; };

}
