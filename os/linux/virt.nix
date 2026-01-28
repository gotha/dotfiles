{ username, ... }:
{

  users = {
    users.${username}.extraGroups = [ "docker" ];
    groups.libvirtd.members = [ "${username}" ];
  };

  virtualisation = {
    docker = {
      enable = true;
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
    };
    libvirtd.enable = true;
  };
}
