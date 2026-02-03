# Mail Server configuration

1. Generate DKIM Keys

```sh
# On bastion or locally
mkdir -p /tmp/dkim
opendkim-genkey -b 2048 -d hgeorgiev.com -s mail -D /tmp/dkim
# This creates:
# - mail.private (private key - encrypt with sops)
# - mail.txt (public key for DNS)
```

2. Encrypt DKIM Private Key with SOPS

```sh
sops -e /tmp/dkim/mail.private > secrets/dkim-key.enc
```

3. Configure DNS Records

```zonefile
; A records
mail	60	IN	A	64.226.77.137

; MX records
@	60	IN	MX	10 mail.hgeorgiev.com.

; TXT records
@	60	IN	TXT	"v=spf1 mx a ip4:64.226.77.137 ~all"
_dmarc	60	IN	TXT	"v=DMARC1; p=quarantine; rua=mailto:postmaster@hgeorgiev.com"
mail._domainkey	60	IN	TXT	"<content of mail.txt>" ; ----- DKIM key mail for hgeorgiev.com
```

To configure PTR (reverse DNS) set the name of the droplet in Digitalocean to mail.hgeorgiev.com.

4. Add Mail Users
Edit hosts/bastion/mail.nix to add users in the vmailbox, virtual, and dovecot/users sections:

```sh
# Generate password hash
doveadm pw -s SHA512-CRYPT
```
