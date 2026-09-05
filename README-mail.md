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

## 4. Add or Rotate Mail Users

Passwords live in two encrypted files and must be kept in sync:

- `secrets/mailboxes.json` - cleartext, read by aerc on the client side
- `secrets/dovecot-users` - the dovecot passwd-file of BLF-CRYPT hashes,
  deployed to bastion as `/run/secrets/dovecot_users`

Both are gitignored; only their `.enc` counterparts are committed.

```sh
# 1. Add or change the cleartext password
$EDITOR secrets/mailboxes.json
sops -e secrets/mailboxes.json > secrets/mailboxes.enc.json

# 2. Generate the matching hash and put it in the passwd-file as
#    user@domain:{BLF-CRYPT}$2y$11$...
doveadm pw -s BLF-CRYPT -r 11
$EDITOR secrets/dovecot-users
sops -e secrets/dovecot-users > secrets/dovecot-users.enc

# 3. Verify a hash matches its password before deploying
doveadm pw -t '{BLF-CRYPT}$2y$11$...' -p 'the-password'
```

A new mailbox also needs an entry in the `vmailbox` map in
`hosts/bastion/mail.nix`, and an alias in `virtual` if it should receive
mail under other addresses.

BLF-CRYPT rather than ARGON2ID: bastion is a 1 GB droplet, and argon2's
default 64 MiB per verification times dovecot's auth workers is an
out-of-memory vector on an internet-facing port. bcrypt's cost is CPU-only,
and `-r 11` lands around 250 ms there.

## 5. Verify DKIM Signing

After deployment, verify DKIM is working:

```sh
# Check rspamd status
systemctl status rspamd

# Send a test email and check headers for DKIM-Signature
# Or use online tools like mail-tester.com
```
