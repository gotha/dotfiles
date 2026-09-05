_: {
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 10d";
  };

  # When disk space runs low, have the daemon collect garbage mid-build; once
  # free space drops below min-free it deletes until max-free is available,
  # rather than failing the build or wedging the filesystem.
  nix.settings = {
    min-free = 20 * 1024 * 1024 * 1024; # 20 GiB
    max-free = 100 * 1024 * 1024 * 1024; # 100 GiB
  };
}
