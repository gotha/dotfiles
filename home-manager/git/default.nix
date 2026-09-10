{
  config,
  pkgs,
  ...
}:
let
  cfg = import ../../config/default.nix;
in
{

  home = {
    packages = with pkgs; [
      git
      git-lfs
    ];
  };

  xdg.configFile."git/ignore".source = ./global_ignore;

  programs.git = {
    enable = true;

    settings = {
      user = {
        name = cfg.username;
        email = "h.georgiev@hotmail.com";
      };

      init = {
        defaultBranch = "main";
      };

      push = {
        autoSetupRemote = true;
      };

      core = {
        editor = "nvim";
        excludesfile = "~/.config/git/ignore";
      };

      diff = {
        tool = "vimdiff";
      };

      filter."lfs" = {
        process = "git-lfs filter-process";
        required = true;
        clean = "git-lfs clean -- %f";
        smudge = "git-lfs smudge -- %f";
      };

      pull = {
        rebase = true;
      };

      url."git@github.com:" = {
        insteadOf = "https://github.com/";
      };
    };

    # ssh rather than pgp: the key is the one that already gets this machine
    # into its servers, it needs no agent or keyring, and github verifies it
    # once the same key is added there a second time as a Signing Key.
    signing = {
      format = "ssh";
      key = "${config.home.homeDirectory}/${cfg.signingKey}";
      signByDefault = true;

      # Without this, git can sign but not verify: `git verify-commit` and
      # `git log --show-signature` have no set of keys to trust and report
      # every commit as unverified. One line per machine, because each has its
      # own key - a commit made on lucie is verified on mucie only if lucie's
      # key is listed here. github checks its own copy and needs none of this.
      allowedSigners = builtins.concatStringsSep "\n" (
        map (key: "${cfg.email} ${key}") cfg.signingPublicKeys
      );
    };

  };
}
