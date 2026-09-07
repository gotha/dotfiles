# unak-loko.org - record data only; the resource and import blocks that consume
# this live in main.tf. Keys are "<name>/<type>", which is also the
# import id Hetzner expects, so adding a record here is a one-line change.
#
# SOA is deliberately absent: the API owns it and bumps its serial.
#
# This domain runs no mail, and the four records below say so rather than
# leaving it to be inferred from an absent MX. Without them the domain has no
# SPF or DMARC to fail against, so anyone may spoof it, and a missing MX makes
# senders fall back to the apex A record - which would walk delivery attempts
# onto the host serving the website.
locals {
  unak_loko_org = {
    "@/A"   = { ttl = 60, records = ["134.122.64.210"] }
    "www/A" = { ttl = 600, records = ["134.122.64.210"] }
    "@/NS" = {
      ttl = 60
      records = [
        "ns.second-ns.com.",
        "ns1.your-server.de.",
        "ns3.second-ns.de.",
      ]
    }

    # Null MX, RFC 7505: "." as the exchange means the domain accepts no mail
    # at all. A sender fails immediately and permanently instead of retrying
    # for days or falling through to the apex A record.
    "@/MX" = { ttl = 3600, records = ["0 ."] }

    # No host is authorised to send as this domain. -all is a hard fail, not
    # the ~all softfail the domains that do carry mail use.
    "@/TXT" = { ttl = 3600, records = ["\"v=spf1 -all\""] }

    # p=reject asks receivers to drop anything claiming to be from here, and
    # sp=reject extends that to subdomains, which do not inherit SPF on their
    # own. Strict alignment because nothing legitimate has to pass.
    "_dmarc/TXT" = {
      ttl     = 3600
      records = ["\"v=DMARC1; p=reject; sp=reject; adkim=s; aspf=s\""]
    }

    # An empty p= is a revoked key (RFC 6376), and the wildcard applies it to
    # every selector, so no DKIM signature can validate for this domain
    # whatever selector it claims.
    "*._domainkey/TXT" = { ttl = 3600, records = ["\"v=DKIM1; p=\""] }
  }
}
