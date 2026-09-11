# ssh client config, and the agent that caches the key's passphrase.
#
# The key does two jobs now - logging into the servers, and signing commits -
# so without an agent every commit prompts for the passphrase. This is what
# replaces the gpg-agent that used to cache the pgp signing passphrase.
{
  config,
  pkgs,
  lib,
  ...
}:
let
  wireguard = import ../../config/wireguard.nix;
in
{
  programs.ssh = {
    enable = true;

    # The module's legacy defaults are on their way out and warn if left
    # implicit, so they are written out below instead - upstream's own
    # replacement snippet, with AddKeysToAgent changed.
    enableDefaultConfig = false;

    settings = {
      # From config/wireguard.nix rather than written out again - flake.nix
      # reads the same value for deploy-rs, so the address lives in one place.
      bastion.hostname = wireguard.bastion.publicIP;

      "*" = {
        # Load the key into the agent on first use and keep it there, so the
        # passphrase is typed once per session rather than once per commit.
        AddKeysToAgent = "yes";

        ForwardAgent = false;
        Compression = false;
        ServerAliveInterval = 0;
        ServerAliveCountMax = 3;
        HashKnownHosts = false;
        UserKnownHostsFile = "~/.ssh/known_hosts";
        ControlMaster = "no";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "no";
      }
      # UseKeychain stores the passphrase in the login keychain, so it survives
      # a reboot as well as a session. Darwin only: ssh on linux rejects the
      # keyword outright, which is why this is not one shared file.
      // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin { UseKeychain = "yes"; };
    };
  };

  # macOS already runs an agent through launchd; linux has to be asked.
  services.ssh-agent.enable = pkgs.stdenv.hostPlatform.isLinux;

  # UseKeychain above only helps once a passphrase is already cached there,
  # and that caching happens inside `ssh`/`ssh-add` when they load a key -
  # never inside `ssh-keygen -Y sign`, which is what git uses to sign commits
  # and reads the key file directly. Since this key is used for signing far
  # more often than for logging into a server, it can go a long time without
  # ever passing through `ssh` itself, so the keychain stays empty and every
  # commit prompts again after a reboot. Loading whatever the keychain already
  # holds back into the agent at login closes that gap - it's a no-op the
  # first time, before anything has been cached with `--apple-use-keychain`.
  launchd.agents.ssh-add-keychain = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    enable = true;
    config = {
      ProgramArguments = [
        "/usr/bin/ssh-add"
        "--apple-load-keychain"
      ];
      RunAtLoad = true;
      KeepAlive = false;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/ssh-add-keychain.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/ssh-add-keychain.log";
    };
  };
}
