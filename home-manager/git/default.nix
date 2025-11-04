{ pkgs, ... }: {

  home.packages = with pkgs; [ git git-lfs ];

  xdg.configFile."git/ignore".source = ./global_ignore;

  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "gotha";
        email = "h.georgiev@hotmail.com";
      };

      init = { defaultBranch = "main"; };

      push = { autoSetupRemote = true; };

      core = {
        editor = "nvim";
        excludesfile = "~/.config/git/ignore";
      };

      diff = { tool = "vimdiff"; };

      filter."lfs" = {
        process = "git-lfs filter-process";
        required = true;
        clean = "git-lfs clean -- %f";
        smudge = "git-lfs smudge -- %f";
      };

      pull = { rebase = true; };
    };

    signing = {
      key = "C3AB3AC0115DD07B5ACA476E8D8E74E4033D192C";
      signByDefault = true;
    };

  };
}
