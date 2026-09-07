# hgeorgiev.com - record data only; the resource and import blocks that consume
# this live in main.tf. Keys are "<name>/<type>", which is also the
# import id Hetzner expects, so adding a record here is a one-line change.
#
# SOA is deliberately absent: the API owns it and bumps its serial.
locals {
  hgeorgiev_com = {
    "@/A"           = { ttl = 60, records = ["134.122.64.210"] }
    "argo.ramo/A"   = { ttl = 60, records = ["138.68.104.26"] }
    "cachix/A"      = { ttl = 60, records = ["134.122.64.210"] }
    "chalgarr/A"    = { ttl = 60, records = ["64.226.77.137"] }
    "dissona/A"     = { ttl = 60, records = ["64.226.77.137"] }
    "ftfy/A"        = { ttl = 60, records = ["134.122.64.210"] }
    "mail/A"        = { ttl = 60, records = ["64.226.77.137"] }
    "new/A"         = { ttl = 60, records = ["134.122.64.210"] }
    "new.xoomify/A" = { ttl = 60, records = ["134.122.64.210"] }
    "nextcloud/A"   = { ttl = 60, records = ["64.226.77.137"] }
    "ramo/A"        = { ttl = 60, records = ["138.68.104.26"] }
    "video/A"       = { ttl = 60, records = ["64.226.77.137"] }
    "webmail/A"     = { ttl = 60, records = ["64.226.77.137"] }
    "www/A"         = { ttl = 60, records = ["134.122.64.210"] }
    "xoomify/A"     = { ttl = 60, records = ["134.122.64.210"] }
    "imap/CNAME"    = { ttl = 60, records = ["mail.hgeorgiev.com."] }
    "smtp/CNAME"    = { ttl = 60, records = ["mail.hgeorgiev.com."] }
    "@/MX"          = { ttl = 60, records = ["10 mail.hgeorgiev.com."] }
    "@/NS" = {
      ttl = 60
      records = [
        "ns.second-ns.com.",
        "ns1.your-server.de.",
        "ns3.second-ns.de.",
      ]
    }
    "@/TXT" = { ttl = 60, records = ["\"v=spf1 mx a ip4:64.226.77.137 ~all\""] }
    "_dmarc/TXT" = {
      ttl = 60
      records = [
        "\"v=DMARC1; p=quarantine; rua=mailto:postmaster@hgeorgiev.com\"",
      ]
    }
    "mail._domainkey/TXT" = {
      ttl     = 60
      comment = "----- DKIM key mail for hgeorgiev.com"
      records = [
        "\"v=DKIM1; k=rsa; \" \"p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA1SHH23Ws+ihaZxbUDS+XKTlnrYUQFcg0/othMJZr3/gaVSGx47MuMUtWuSefpiPMkGpud7fKTsjThUsNMDP3EMEjCyh7y6sq59kdkJuNyz/YV+42uyBNXtlXNR8U82nNU53l1Ymd+Euc4PiEjWtof5rOITWJDb6uk2tmj942rVciVjSL8gYRxKLFZ2WLVAEtmFLi4vVIN2oI9t\" \"AICS0RyEGgjFy4il+3aPqniDUKHIRrDHFWvcWfOgEI7z2YFRwXFZcB7B/Sz4POoePatTxdHzUngmV/b0Adh00OZ5rsz0dTrX+VeCT52J5JoSu5nugdjv0gFvt8lg61tukWo4kizQIDAQAB\"",
      ]
    }
  }
}
