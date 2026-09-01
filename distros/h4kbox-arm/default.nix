# h4kbox for aarch64-linux.
#
# Layered on top of ./distros/h4kbox (see distro.h4kbox-arm in flake.nix), so
# anything added to h4kbox lands here too. All this module does is drop what
# cannot work on ARM and hold whatever is ARM-specific.
#
# Deliberately does not import ../devbox-arm, even though the two overlap
# today. That module rebuilds _module.args.userPackages from *devbox's* package
# lists and mkForces the result, so importing it here would quietly discard any
# package list h4kbox grows of its own. The two distros are also free to make
# different ARM concessions - h4kbox dropping something devbox keeps, or the
# reverse - and that cannot be expressed through an import.
#
# Nothing in the Hyprland stack needs dropping: hyprland, hyprpaper, hyprlock,
# hypridle, hyprpicker and quickshell all have aarch64-linux builds, checked
# against nixpkgs before wiring this up. If one regresses on ARM, this is where
# it gets disabled, keeping ../h4kbox free of arch conditionals.
{
  lib,
  pkgs,
  stablePkgs,
  username,
  ...
}:
let
  # Rebuilt from the same sources h4kbox inherits from devbox: a module cannot
  # read the _module.args.userPackages it is also redefining. Keep in step with
  # the userPackages/linuxUserPackages bindings in ../devbox/default.nix, and
  # add any h4kbox-specific list here too or the filter below will drop it.
  userPackages =
    import ../../config/packages-user.nix { inherit pkgs stablePkgs; }
    ++ import ../../os/linux/packages-user.nix { inherit pkgs; };
in
{
  # Filter on meta.platforms rather than naming the casualties - a hardcoded
  # list goes stale as soon as someone adds a package. As of now this drops
  # spotify, slack and zoom-us, none of which nixpkgs builds for ARM Linux.
  # Nothing in config/packages.nix is affected, so environment.systemPackages
  # is left alone; mkForce there would also wipe the contributions every other
  # NixOS module makes to it.
  _module.args.userPackages = lib.mkForce (
    lib.filter (lib.meta.availableOn pkgs.stdenv.hostPlatform) userPackages
  );

  # graphite-cli wraps its prebuilt binary in a buildFHSEnv on Linux, then runs
  # `gt` under bubblewrap to generate shell completions. bubblewrap has to
  # create a user namespace and qemu-user cannot do that, so the aarch64 build
  # dies on an x86_64 builder - and nixpkgs caches no aarch64-linux binary, so
  # it is a build rather than a fetch. Drop only the completion step; the tool
  # itself is untouched. Harmless on a native ARM builder, where the whole
  # thing would have worked anyway - which is why it stays even though the Mac
  # builder is native aarch64: lucie builds ARM under emulation.
  nixpkgs.overlays = [
    (_final: prev: {
      graphite-cli = prev.graphite-cli.override {
        buildFHSEnv =
          args:
          prev.buildFHSEnv (
            args
            // {
              extraInstallCommands = ''
                ln -s $out/bin/graphite-cli $out/bin/gt
              '';
            }
          );
      };
    })
  ];

  # crush and codex are Go/Rust builds with nothing cached for aarch64-linux,
  # and under qemu-user a single crush compile ran over 20 minutes before its
  # test suite even started. Drop both rather than pay that on every image
  # build. disabledModules un-imports the home-manager modules that pull them
  # in, so their config files go too. The crush_openai_key sops secret is
  # declared over in ../../home-manager/sops and stays - harmless, just unused.
  #
  # This is a build-time concession, not an ARM incompatibility: both build
  # fine natively. Drop these two lines if h4kbox-arm is only ever built on a
  # native ARM builder.
  home-manager.users.${username}.disabledModules = [
    ../../home-manager/codex
    ../../home-manager/crush
  ];

  # Steam is x86_64-linux only, and its module switches on
  # hardware.graphics.enable32Bit, which asserts on any non-x86_64 system - so
  # it has to go explicitly, no package list mentions it.
  programs.steam.enable = lib.mkForce false;
}
