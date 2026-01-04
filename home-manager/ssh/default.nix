{ pkgs, ... }: {

  home.file = {
    ".ssh/config".source = ./config;
  };

}

