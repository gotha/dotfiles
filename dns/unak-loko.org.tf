# unak-loko.org - record data only; the resource and import blocks that consume
# this live in main.tf. Keys are "<name>/<type>", which is also the
# import id Hetzner expects, so adding a record here is a one-line change.
#
# SOA is deliberately absent: the API owns it and bumps its serial.
locals {
  unak_loko_org = {
    "@/A"         = { ttl = 60, records = ["134.122.64.210"] }
    "control/A"   = { ttl = 601, records = ["134.122.64.210"] }
    "mail/A"      = { ttl = 60, records = ["213.133.104.4"] }
    "www/A"       = { ttl = 600, records = ["134.122.64.210"] }
    "ftp/CNAME"   = { ttl = 60, records = ["www.unak-loko.org."] }
    "imap/CNAME"  = { ttl = 60, records = ["mail.unak-loko.org."] }
    "pop/CNAME"   = { ttl = 60, records = ["mail.unak-loko.org."] }
    "relay/CNAME" = { ttl = 60, records = ["mail.unak-loko.org."] }
    "smtp/CNAME"  = { ttl = 60, records = ["mail.unak-loko.org."] }
    "@/NS" = {
      ttl = 60
      records = [
        "ns.second-ns.com.",
        "ns1.your-server.de.",
        "ns3.second-ns.de.",
      ]
    }
  }
}
