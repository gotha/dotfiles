{
  channel = "https://channels.nixos.org/nixos-unstable";
  timeZone = "Europe/Sofia";
  username = "gotha";
  email = "h.georgiev@hotmail.com";
  domain = "hgeorgiev.com";
  # Commits are signed with ssh rather than pgp, so this is a public key path
  # rather than a key id. Per machine, and never copied between them.
  signingKey = ".ssh/id_ed25519.pub";

  # Every machine that signs commits, so any of them can verify the others.
  # Add a line when a new machine gets a key; nothing breaks if one is missing,
  # its commits just read as unverified locally.
  signingPublicKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJV6BjLjS8zzj1DDZMWc1QvCkl0UwOqzvqDFfiZzeOdt gotha@mucie"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKWrN+WtkMXnBK4ee1QDBsdElU8+UaStiND3Hxd2qBLJ gotha@lucie"
  ];
  sshPublicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC19hl9dSEt8+agT7kaCtpxEN8go5X9u3bUPvxXNrhOdFiSpe9ykP7m/dif7jZsUUOWG7N27wrlnUdm3RFu7r8DVE/fJe4XsMD3rQNrO0SBVMcdzKZ32YZPkQPfyvLj0a36pTYJoT6cfKECDCJX7mXKq8SYbE0Wqh+OMq/MKnWpZ9x5x7cIUFZyPH9tG9CXVT3/SkNAjcz1X5S3pWqZkrLIN1scljvOkMz9GRq8c8yD8ecJSYiZimNXSaH47VDGq2AW8Ccb4i0JGpTXeGChRQr09aN0IZyhrDH9smA0AhWYHKxNMfxCSFKWBIKG7e1p0BIhwZAn3r/TrqmlvsPyHjdj0gcJGIVNJSKtmCl6TjLb9xV1qTcmfFaNJHDEv+zQoVfCHHV5YCIiAQ1w1faIhNPqnNi5Pk0XF1gVTu/V4K5G5J4CYflfwHZDVrPYBl4xYLJ6ylEhSKbiWJaH9lQsLHJoUwPECZ2RYNlGnfPxLIz3FQGphLv3Lj7fPZuHJMRaJM=";
}
