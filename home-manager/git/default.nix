{
  pkgs,
  config,
  ...
}:
let
  cfg = config.programs.gitUser;
in
{
  imports = [
    ../../config/modules/git-user.nix
  ];

  config = {
    home.packages = with pkgs; [
      git
      git-lfs
    ];

    xdg.configFile."git/ignore".source = ./global_ignore;

    programs.git = {
      enable = true;

      settings = {
        user = {
          name = cfg.name;
          email = cfg.email;
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
      };

      signing = {
        key = cfg.gpgSigningKey;
        signByDefault = true;
      };

    };
  };
}
