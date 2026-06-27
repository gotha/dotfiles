{ pkgs, ... }:
let
  cfg = import ../../config/default.nix;
in
{

  home.packages = with pkgs; [
    git
    git-lfs
    pinentry-curses # passphrase prompt for GPG-signing commits
  ];

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

    signing = {
      key = "C3AB3AC0115DD07B5ACA476E8D8E74E4033D192C";
      signByDefault = true;
    };

  };

  # GPG agent wired to use pinentry-curses for the commit-signing passphrase prompt.
  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-curses;
  };
}
