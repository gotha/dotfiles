_: {
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 10d";
  };

  # Between weekly runs the store can still fill up - lucie's root sat at 96%
  # while a nightly build tried to write 47 GB of CUDA closure onto it. These
  # make the daemon collect garbage mid-build instead: once free space drops
  # below min-free it deletes until max-free is available, rather than failing
  # the build or wedging the filesystem.
  nix.settings = {
    min-free = 20 * 1024 * 1024 * 1024; # 20 GiB
    max-free = 100 * 1024 * 1024 * 1024; # 100 GiB
  };
}
