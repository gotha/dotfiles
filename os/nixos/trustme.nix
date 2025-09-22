{ username, ... }: {
  nix.settings = { trusted-users = [ "root" "${username}" ]; };
}
