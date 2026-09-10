# sops-nix wiring, and nothing about any particular secret.
#
# Individual secrets are declared by the module that reads them, next to the
# encrypted file they come from - see ../aerc for the shape. A module that
# needs one imports this to pull in the sops-nix module and the age key;
# importing it twice is harmless, since the module system merges them.
#
# Keeping the declarations with their consumers means a secret and its
# .enc file move, or get deleted, together with the thing that wanted them.
{
  config,
  inputs,
  pkgs,
  ...
}:
let
  keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
in
{

  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  home.packages = [ pkgs.sops ];

  # The age key this user decrypts with. Created per machine and never copied:
  #   nix shell nixpkgs#age -c age-keygen -o ~/.config/sops/age/keys.txt
  #
  # A workstation key rather than the host key at /etc/ssh, because activation
  # runs as this user and cannot read a root-owned file. It carries no
  # passphrase - sops reads it unattended - which is why it is kept separate
  # from ~/.ssh/id_ed25519, where a passphrase costs nothing.
  sops.age.keyFile = keyFile;

  # sops-nix reads the path above directly, so activation needs nothing more.
  # The sops command does not: it looks at this variable, and otherwise at a
  # default under Go's UserConfigDir, which on darwin is
  # ~/Library/Application Support rather than ~/.config - so on a Mac it never
  # finds the key and reports "no identity matched any of the recipients",
  # which reads like a recipient problem rather than a missing key.
  home.sessionVariables.SOPS_AGE_KEY_FILE = keyFile;

}
