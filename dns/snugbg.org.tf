# snugbg.org - record data only; the resource and import blocks that consume
# this live in main.tf. Keys are "<name>/<type>", which is also the
# import id Hetzner expects, so adding a record here is a one-line change.
#
# SOA is deliberately absent: the API owns it and bumps its serial.
locals {
  snugbg_org = {
    "@/A" = {
      ttl = 60
      records = [
        "185.199.109.153",
        "185.199.110.153",
        "185.199.111.153",
      ]
    }
    "www/CNAME" = { ttl = 60, records = ["sofia-nix-user-group.github.io."] }
    "@/NS" = {
      ttl = 60
      records = [
        "helium.ns.hetzner.de.",
        "hydrogen.ns.hetzner.com.",
        "oxygen.ns.hetzner.com.",
      ]
    }
    "_github-pages-challenge-sofia-nix-user-group/TXT" = { ttl = 60, records = ["\"c95a56e85221905e245097379e7c8b\""] }
  }
}
