{ wireguard, ... }:
{
  # Split DNS, the client half of hosts/bastion/internal.nix: only .internal
  # goes to dnsmasq on bastion, everything else stays with whatever resolver
  # the current network hands out, so a bastion outage costs internal names
  # rather than all name resolution. macOS reads one file per domain out of
  # /etc/resolver, and the filename is the domain the file applies to.
  #
  # bastion answers the whole domain with a wildcard and then routes the
  # packets, so adding a service on lucie needs no change here either.
  #
  # Names resolve only while wg0 is up - the address below is unreachable
  # otherwise, so lookups fail fast rather than leaking to a public resolver.
  environment.etc."resolver/internal".text = ''
    nameserver ${wireguard.bastion.privateIP}
  '';
}
