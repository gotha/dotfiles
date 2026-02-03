{ username, pkgs, ... }:
let
  docker-compose-wrapper = pkgs.writeShellScriptBin "docker-compose" ''
    exec docker compose "$@"
  '';
in
{

  users = {
    users.${username}.extraGroups = [ "docker" ];
    groups.libvirtd.members = [ "${username}" ];
  };

  environment.systemPackages = [ docker-compose-wrapper ];

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
