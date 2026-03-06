# Mail Server configuration

The mail server uses:
- **Postfix** - SMTP server
- **Dovecot** - IMAP server
- **rspamd** - DKIM signing (replaced OpenDKIM which is unmaintained)

## 1. Generate DKIM Keys

```sh
# On bastion or locally using rspamd's tool
rspamadm dkim_keygen -s mail -d hgeorgiev.com -b 2048 -k /tmp/mail.key > /tmp/mail.txt

# Or using openssl directly
openssl genrsa -out /tmp/mail.private 2048
openssl rsa -in /tmp/mail.private -pubout -out /tmp/mail.pub

# This creates:
# - mail.private / mail.key (private key - encrypt with sops)
# - mail.txt / mail.pub (public key for DNS)
```

## 2. Encrypt DKIM Private Key with SOPS

```sh
sops -e /tmp/mail.private > secrets/dkim-key.enc
```

The key will be deployed to `/var/lib/rspamd/dkim/hgeorgiev.com.mail.key` on bastion.

## 3. Configure DNS Records

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

## 4. Add Mail Users

Edit `hosts/bastion/mail.nix` to add users in the vmailbox, virtual, and dovecot/users sections:

```sh
# Generate password hash
doveadm pw -s SHA512-CRYPT
```

## 5. Verify DKIM Signing

After deployment, verify DKIM is working:

```sh
# Check rspamd status
systemctl status rspamd

# Send a test email and check headers for DKIM-Signature
# Or use online tools like mail-tester.com
```
