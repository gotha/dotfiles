{ username, ... }:
{
  # Non-root access to ZSA keyboard firmware (Moonlander, Voyager, Ergodox EZ,
  # Planck EZ) for flashing and Oryx/Keymapp live training.
  #
  # Enabling this installs pkgs.zsa-udev-rules into services.udev.packages
  # (the same 50-oryx / 50-wally rules ZSA ships for /etc/udev/rules.d) and
  # creates the "plugdev" group.
  hardware.keyboard.zsa.enable = true;

  # The zsa module creates the plugdev group but does not add anyone to it.
  # (The packaged rules use TAG+="uaccess", so the logged-in user already gets
  # access; plugdev membership matches the upstream instructions and covers
  # tools that still look for the group.)
  users.users.${username}.extraGroups = [ "plugdev" ];
}
