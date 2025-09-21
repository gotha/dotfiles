{ username, pkgs, userPackages, ... }: {
  users = {
    users.${username} = {
      isNormalUser = true;
      password = "asdfasdf";
      shell = pkgs.zsh;
      extraGroups = [ "wheel" "networkmanager" "video" "render" ];
      openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCyE0L8ivXyEMysyBiEUvc5xTmDyC4OpaljKvwPKsiZ16PvxM61IHumssaPUGaWYBxpkdQwVqeQigtI3yTz6xHV+Y05Po7ptqBs6LuXFWJ8dExTASq48deYh48M/hoELy6f9Ascs2/WZ39TK4X/Ok3/YH47K1A/o+qu3lfGswAJ393xQ4HioTMETPFag0NigwRPwSaBTJZHkKoMdsOWYPBUwE5l0wjoLLqkWTs0fD/78cxk5ctMaKWiqTq/iEt0Enw7L001rlN2ew24fnKOpkFEC7Wa3MYc3EXH1O0iVQSGC+rFF3hM+D7/m2NIGAvhnWmoBiCOZCUJl9RWehe8LQ1H ${username}"
      ];
      packages = userPackages;
    };
  };

  security.sudo.wheelNeedsPassword = false;
}
