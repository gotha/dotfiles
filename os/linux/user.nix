{
  username,
  pkgs,
  userPackages,
  config,
  ...
}:
{
  imports = [
    ../config/modules/linux-user.nix
  ];

  config = {
    users = {
      users.${username} = {
        isNormalUser = true;
        password = "asdfasdf";
        shell = pkgs.zsh;
        extraGroups = [
          "wheel"
          "networkmanager"
          "video"
          "render"
        ];
        openssh.authorizedKeys.keys = [
          "${config.linuxUser.sshPublicKey} ${username}"
        ];
        packages = userPackages;
      };
    };

    security.sudo.wheelNeedsPassword = false;
  };
}
