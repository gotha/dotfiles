;; Exported on 2026-08-25T17:42:53Z
$ORIGIN	dissona.app.
$TTL	7200

@	60	IN	SOA	ns1.your-server.de. postmaster.your-server.de. 2026082502 86400 10800 3600000 3600

; NS records
@	60	IN	NS	ns.second-ns.com.
@	60	IN	NS	ns1.your-server.de.
@	60	IN	NS	ns3.second-ns.de.

; A records
@	60	IN	A	64.226.77.137
www	60	IN	A	64.226.77.137

; MX records
@	70	IN	MX	10 mail.hgeorgiev.com.

; TXT records
@	60	IN	TXT	"v=spf1 mx a ip4:64.226.77.137 ~all"
_dmarc	60	IN	TXT	"v=DMARC1; p=none; rua=mailto:postmaster@dissona.app"
mail._domainkey	60	IN	TXT	"v=DKIM1; k=rsa; " "p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAv5lL+tQ4RWZe4uzle1iqw2+vNIfpvRV1RIer2f5DkBJgrstV5Y8Gr7qKggfC7Mj21DxauwjhKGe1c0nXIKGRPlaf/Anysl9gPwoiCaGGsKBqqs/xlJzHW5NTJ6qzA6rIblXMjGKNaak43Z1vdIoy3esGe9My0RdNIAQneUp+hn7EhmHwAoe66WZrCfOknyq8/hGa/+/qvasSbdQU8" "QXYXmkcGSe5gIyK6wflTQCyEGgM6AtD0toquKfBFKEp5eCCAaWbpQnsron2km68nBInA+d3IH6VFCUQ3GOxzhYfW7O3sVUBqnDKqy1durYbgiib+/Kzz8L3+YElmsHuhg0fRQIDAQAB"

