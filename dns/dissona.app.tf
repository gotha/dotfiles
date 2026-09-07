# dissona.app - record data only; the resource and import blocks that consume
# this live in main.tf. Keys are "<name>/<type>", which is also the
# import id Hetzner expects, so adding a record here is a one-line change.
#
# SOA is deliberately absent: the API owns it and bumps its serial.
locals {
  dissona_app = {
    "@/A"   = { ttl = 60, records = ["64.226.77.137"] }
    "www/A" = { ttl = 60, records = ["64.226.77.137"] }
    "@/MX"  = { ttl = 70, records = ["10 mail.hgeorgiev.com."] }
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
        "\"v=DMARC1; p=quarantine; rua=mailto:postmaster@dissona.app\"",
      ]
    }
    "mail._domainkey/TXT" = {
      ttl = 60
      records = [
        "\"v=DKIM1; k=rsa; \" \"p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAv5lL+tQ4RWZe4uzle1iqw2+vNIfpvRV1RIer2f5DkBJgrstV5Y8Gr7qKggfC7Mj21DxauwjhKGe1c0nXIKGRPlaf/Anysl9gPwoiCaGGsKBqqs/xlJzHW5NTJ6qzA6rIblXMjGKNaak43Z1vdIoy3esGe9My0RdNIAQneUp+hn7EhmHwAoe66WZrCfOknyq8/hGa/+/qvasSbdQU8\" \"QXYXmkcGSe5gIyK6wflTQCyEGgM6AtD0toquKfBFKEp5eCCAaWbpQnsron2km68nBInA+d3IH6VFCUQ3GOxzhYfW7O3sVUBqnDKqy1durYbgiib+/Kzz8L3+YElmsHuhg0fRQIDAQAB\"",
      ]
    }
  }
}
