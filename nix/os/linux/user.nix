{ username, pkgs, userPackages, ... }: {
  users = {
    users.${username} = {
      isNormalUser = true;
      password = "asdfasdf";
      shell = pkgs.zsh;
      extraGroups = [ "wheel" "networkmanager" "video" "render" ];
      packages = userPackages;
    };
  };
}
