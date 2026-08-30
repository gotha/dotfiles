# Drop MPD from the QEMU images.
#
# Imported directly by mkDevboxQemuImage in flake.nix rather than folded into
# ./default.nix next to it: that module is the label-and-grub host used by
# nixosConfigurations.devbox and packages.bae-qemu, and the repart images do
# not import it - ../../os/linux/repart-image.nix mkForces both of those
# settings back out again.
#
# Two independent reasons to drop mpd, either of which is enough on its own:
#
# 1. None of the devbox-qemu runners in flake.nix pass -audiodev or attach a
#    sound device, so the guest has no audio hardware at all. PipeWire comes up
#    with no sink and mpd's pipewire output has nowhere to play. The daemon is
#    dead weight in the image.
#
# 2. The image cannot be built on a Mac while mpd is enabled. NixOS validates
#    the generated mpd.conf by actually running mpd under expect(1)
#    (nixos/modules/services/audio/mpd.nix - the checkPhase on the mpd.conf
#    writeTextFile), and expect needs a pty. Determinate Nix's external Linux
#    builder runs builds as an unprivileged uid in a /dev that is a bare
#    devtmpfs with no devpts mounted, so /dev/ptmx is unusable and expect dies
#    with "The system has no more ptys". There is no knob on the module to skip
#    that check and a derivation cannot mount devpts for itself, so the only
#    way past it is to not generate an mpd.conf.
#
# services.mpd.settings.music_directory stays set over in ../../distros/devbox,
# so home-manager/mpd/ncmpcpp still reads a sensible path out of osConfig.
# The real devbox hosts, built on Linux, keep mpd.
{ lib, ... }:
{
  services.mpd.enable = lib.mkForce false;
}
