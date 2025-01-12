{ }: {
  imports = [ ./hardware-configuration.nix ./boot-loader.nix ../nixos ];

  networking.hostName = "thucie";
}
