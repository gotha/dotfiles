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

    # Mail, served by bastion (mail.hgeorgiev.com) alongside hgeorgiev.com and
    # dissona.app - no mail/A here, the MX target resolves via the
    # hgeorgiev.com zone. The apex A above points at GitHub Pages, not
    # bastion, so SPF names the mail server by ip4 rather than by "a".
    "@/MX"  = { ttl = 60, records = ["10 mail.hgeorgiev.com."] }
    "@/TXT" = { ttl = 60, records = ["\"v=spf1 mx ip4:64.226.77.137 ~all\""] }
    "_dmarc/TXT" = {
      ttl = 60
      records = [
        "\"v=DMARC1; p=quarantine; rua=mailto:postmaster@snugbg.org\"",
      ]
    }
    "mail._domainkey/TXT" = {
      ttl     = 60
      comment = "----- DKIM key mail for snugbg.org"
      records = [
        "\"v=DKIM1; k=rsa; \" \"p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAlHH+teR2L7Nookv+COFjgqmn8g7KMM9tZ6tM1jFFENCRDDyQr1aU5LO5ttCiniFX7k6l9KqOxeUXePkvo2RDihK6yf4f36FyNfNArzWIC5FquYDW+fDTllFVLAx9ysCCGW0/d0cfn8CNlQCkhgPTMaiXbAJDr07SeqS+hO/mhMnGtnzarFDnRxyYqhfy4DiYqhkTF+uIT944eHAIV\" \"plBcDiDzA30wUc7c8PmAQvAv5LGCv1sNf7uxbwrLUDu2cQ4Mkbs2scrl+Uz0xqYUuN2PJhHtuH6e+ridLqVqvAmy3I52Lvg6oGDJgFwW4cFluFwkz9TJNy+lxZhxNxEqJiEowIDAQAB\"",
      ]
    }
  }
}
