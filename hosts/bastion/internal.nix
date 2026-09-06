_:
let
  # config/wireguard.nix lists peers anonymously, so there is no name to derive
  # this from; hosts/lucie/wireguard.nix states the same address.
  lucie = "10.100.0.100";
in
{
  # DNS for the VPN, and nothing else - the .internal vhosts live on the host
  # that serves them, in hosts/lucie/internal.nix. bastion answers the name and
  # then forwards packets in the kernel, rather than terminating every
  # connection and opening a second one, which matters on a one-core droplet.
  #
  # A single wildcard covers the whole domain, so a new service on lucie needs
  # no change here. When something is eventually served somewhere else, add a
  # more specific address=/that.internal/<ip> alongside it - dnsmasq matches the
  # longest domain, so the specific record wins over this one.
  #
  # Peers use split DNS: only .internal comes here, everything else stays with
  # their own resolver, so a bastion outage costs internal names rather than all
  # name resolution. The upstreams below are a fallback for clients that cannot
  # express a per-domain rule and have to point at us wholesale.
  services.dnsmasq = {
    enable = true;
    settings = {
      # bind-dynamic attaches to wg0 whenever it shows up, so dnsmasq needs no
      # ordering against the WireGuard unit and survives the interface going
      # away and coming back. bind-interfaces would fail outright at boot, when
      # wg0 does not exist yet.
      interface = "wg0";
      bind-dynamic = true;

      address = "/internal/${lucie}";

      # Resolve upstream directly rather than via /etc/resolv.conf, which on
      # this host points at the DigitalOcean resolvers and would loop back here
      # if it ever listed 127.0.0.1.
      no-resolv = true;
      server = [
        "1.1.1.1"
        "9.9.9.9"
      ];

      domain-needed = true;
      bogus-priv = true;
    };
  };

  # Port 53 on the tunnel only. A resolver that answers on the public IP is an
  # amplification reflector and gets found within days.
  #
  # The rule letting peers reach each other lives in ./wireguard.nix, next to
  # the interface it describes - networking.firewall.extraCommands runs while
  # the chains are still torn down, too early to append to any of them.
  networking.firewall.interfaces.wg0 = {
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = [ 53 ];
  };
}
