;; Exported on 2026-09-06T05:52:44Z
$ORIGIN	hgeorgiev.com.
$TTL	7200

@	60	IN	SOA	ns1.your-server.de. postmaster.your-server.de. 2026082400 14400 1800 604800 7200

; NS records
@	60	IN	NS	ns.second-ns.com.
@	60	IN	NS	ns1.your-server.de.
@	60	IN	NS	ns3.second-ns.de.

; A records
@	60	IN	A	134.122.64.210
argo.ramo	60	IN	A	138.68.104.26
cachix	60	IN	A	134.122.64.210
chalgarr	60	IN	A	64.226.77.137
dissona	60	IN	A	64.226.77.137
ftfy	60	IN	A	134.122.64.210
mail	60	IN	A	64.226.77.137
new	60	IN	A	134.122.64.210
new.xoomify	60	IN	A	134.122.64.210
nextcloud	60	IN	A	64.226.77.137
ramo	60	IN	A	138.68.104.26
video	60	IN	A	64.226.77.137
webmail	60	IN	A	64.226.77.137
www	60	IN	A	134.122.64.210
xoomify	60	IN	A	134.122.64.210

; CNAME records
imap	60	IN	CNAME	mail.hgeorgiev.com.
smtp	60	IN	CNAME	mail.hgeorgiev.com.

; MX records
@	60	IN	MX	10 mail.hgeorgiev.com.

; TXT records
@	60	IN	TXT	"v=spf1 mx a ip4:64.226.77.137 ~all"
_dmarc	60	IN	TXT	"v=DMARC1; p=quarantine; rua=mailto:postmaster@hgeorgiev.com"
mail._domainkey	60	IN	TXT	"v=DKIM1; k=rsa; " "p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA1SHH23Ws+ihaZxbUDS+XKTlnrYUQFcg0/othMJZr3/gaVSGx47MuMUtWuSefpiPMkGpud7fKTsjThUsNMDP3EMEjCyh7y6sq59kdkJuNyz/YV+42uyBNXtlXNR8U82nNU53l1Ymd+Euc4PiEjWtof5rOITWJDb6uk2tmj942rVciVjSL8gYRxKLFZ2WLVAEtmFLi4vVIN2oI9t" "AICS0RyEGgjFy4il+3aPqniDUKHIRrDHFWvcWfOgEI7z2YFRwXFZcB7B/Sz4POoePatTxdHzUngmV/b0Adh00OZ5rsz0dTrX+VeCT52J5JoSu5nugdjv0gFvt8lg61tukWo4kizQIDAQAB" ; ----- DKIM key mail for hgeorgiev.com


