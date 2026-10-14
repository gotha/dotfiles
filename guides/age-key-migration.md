# Moving secrets to age keys, and retiring PGP

## What this changes, and what it does not

**Does not change:** the value of any secret. Every step below re-encrypts
files to a new set of recipients with `sops updatekeys`, which rewrites only
the wrapped data key in the `sops:` metadata. Passwords, tokens and private
keys keep the values they have today.

**Does change:** who can decrypt what. Today one PGP key,
`Infrastructure Secrets C8DDF8A8BDF70670`, is a recipient on all 15 encrypted
files and its private half sits passphrase-free in `/root/.gnupg` on bastion.
Anyone with root there - or with a DigitalOcean snapshot of the disk - can
read every secret in this repository. Afterwards each machine can decrypt only
its own.

## End state

One primitive: ed25519 keypairs. No PGP anywhere.

| where | file | protected by | used for |
| --- | --- | --- | --- |
| each workstation | `~/.ssh/id_ed25519` | passphrase | ssh auth, git signing |
| each workstation | `~/.config/sops/age/keys.txt` | file mode + FileVault | sops decrypt and edit |
| each host | `/etc/ssh/ssh_host_ed25519_key` | already exists | sops decrypt at boot |
| offline | break-glass age key | not on any machine | recovery |

No private key is ever copied between machines. The host keys already exist,
so hosts need nothing provisioned.

Two kinds of age recipient, and they are not interchangeable. All of these are
already in `.sops.yaml`:

```
# workstation keys - ~/.config/sops/age/keys.txt, read by home-manager as you
mucie    age1dl9n3k8q3e7uqwqy7kstqag5km6evsupzjf8ajvftzv9l5g86psqw5rt8r
lucie    age1w955fw2fmxnazd9lpsj9lknzl8l0ccwhcahznmgjqr430mjys4zs2t8vad

# host keys - from /etc/ssh/ssh_host_ed25519_key, read by root at boot
bastion  age1za4avpeg9ppzq9d4dfms2pp0m92x9l0pte85zme35s7tqlux8uwsn53863
lucie    age1p3u6unlxc4dexv0xnnczsrvxjhr4pxw48wrjmvchxvxs866uu93qt686ph
mucie    age144cn0578fcg24aqddssd7fevsyzek758aec000jdtq9u4xdy3ylsp9pye8
```

A host key is `0600 root:root`, so a home-manager module can never use one -
activation runs as you. Putting a workstation key on a `hosts/*/secrets/` rule
is the mirror-image mistake: root at boot cannot read your home directory, so
the machine fails to decrypt and its services do not start.

Re-derive any host key with:

```sh
ssh <host> cat /etc/ssh/ssh_host_ed25519_key.pub | nix run nixpkgs#ssh-to-age
```

## Before you start

- Open the DigitalOcean console for bastion in a browser tab and confirm you
  can log in. Phase 4 changes how bastion decrypts at boot; if it goes wrong,
  dovecot and rspamd do not start and ssh may be the thing that broke.
- Work through the phases in order. Each one is additive until phase 7, so you
  can stop after any phase and still have a working system.
- Do not delete any key until the thing meant to replace it has been proven to
  work. Every phase says what "proven" means.

---

## Phase 1 - create the new keys

### 1.1 Break-glass key

Generate it, then put the private half somewhere that is not one of your
machines: a password manager entry, or printed and filed.

```sh
nix shell nixpkgs#age -c age-keygen -o /tmp/breakglass.txt
cat /tmp/breakglass.txt          # copy both lines somewhere safe
```

Record the `age1...` public line - you will paste it into `.sops.yaml`. Then
destroy the local copy:

```sh
shred -u /tmp/breakglass.txt
```

This key is a recipient on every file and is installed nowhere. It is what
makes losing every workstation survivable.

### 1.2 Workstation age key, on each machine you edit secrets from

```sh
mkdir -p ~/.config/sops/age
nix shell nixpkgs#age -c age-keygen -o ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt
grep public ~/.config/sops/age/keys.txt      # the age1... to use as recipient
```

Run this on mucie, and on lucie if you edit secrets there. Do not copy the
file between them - that is the habit this migration exists to break.

### 1.3 Per-device ssh keys

```sh
ssh-keygen -t ed25519 -C "gotha@mucie"      # use a passphrase
```

Repeat per device with its own comment. These replace the shared 2048-bit
`~/.ssh/id_rsa` in phase 6.

---

## Phase 2 - move each secret next to whatever declares it

`secrets/` at the repo root disappears. The rule is the one already applied to
the home-manager modules: the encrypted file lives beside the module that
declares it.

| file | goes to | because it is declared by |
| --- | --- | --- |
| `dkim-key.enc`, `dkim-key-dissona.enc`, `dovecot-users.enc` | `hosts/bastion/secrets/` | `hosts/bastion/mail.nix` |
| `cachix.enc.json` | `hosts/bastion/secrets/` | `hosts/bastion/nginx.nix` |
| `wg-bastion-key.enc` | `hosts/bastion/secrets/` | `hosts/bastion/wireguard.nix` |
| `grafana.enc.json` | `hosts/lucie/secrets/` | `hosts/lucie/observability.nix` |
| `litellm.enc.json` | `hosts/lucie/secrets/` | `hosts/lucie/litellm.nix` |
| `wg-mucie-key.enc` | `hosts/mucie/secrets/` | `hosts/mucie/wireguard.nix` |
| `hetzner-dns.enc.json` | `dns/secrets/` | the `dns` app in `flake.nix` |

Three files leave rather than move:

- `secrets/.env.enc` - delete it, and the `secrets.".env"` block in
  `home-manager/sops/default.nix`. Nothing reads `~/.env`.
- `secrets/circleci.env` - untracked plaintext left over next to the real
  `.enc`. Delete from disk.
- `secrets/mail.txt` - not a secret. It is the DKIM *public* key in zone-file
  form, already published in DNS. Move it next to `README-mail.md` or delete it.

For each move: `git mv`, then update the `sopsFile` path in the declaring
module to a relative `./secrets/...`. For `hetzner-dns.enc.json` also update
the path in `flake.nix` (the `mkDnsApp` script) and in `README-dns.md`.

Delete `home-manager/sops/.sops.yaml` and the
`home.file.".sops.yaml"` line that deploys it. sops finds a config by walking
up from the file it is encrypting, so inside this repository the root
`.sops.yaml` always wins and that second copy is never consulted. It is also
stale - it names `C3AB3AC0…033D192C`, your git key, which is a recipient on
none of the encrypted files.

Then drop `secrets/*` from `.gitignore` - it protects nothing once the
directory is gone, and leaving it implies a safety net that is not there. The
pre-commit hook in `.githooks/pre-commit` is what guards the new locations.

**Verify:**

```sh
nix eval '.#nixosConfigurations.bastion.config.sops.secrets' --apply builtins.attrNames
nix eval '.#nixosConfigurations.lucie.config.sops.secrets'   --apply builtins.attrNames
nix run .#dns                    # proves dns/secrets/ resolved
```

Deploy every host and confirm services still start.

---

---

## Phase 3 - re-encrypt to the new recipients

`.sops.yaml` in the repository root already carries the rules - read it before
running anything, since it is the whole policy in one file. Each rule pairs a
path with the keys allowed to decrypt what lives there:

| path | recipients | decrypted by |
| --- | --- | --- |
| `home-manager/*/secrets/` | mucie + lucie workstation keys | you, at activation |
| `hosts/bastion/secrets/` | bastion host key | root, at boot |
| `hosts/lucie/secrets/` | lucie host key | root, at boot |
| `hosts/mucie/secrets/` | mucie host key | root, at activation |
| `dns/secrets/` | mucie + lucie workstation keys | you, running `nix run .#dns` |

Every rule also lists the old PGP key. That is deliberate and temporary: it
keeps the current path working so any phase before 7 can be rolled back by
putting a `gnupg` block back. Phase 7 removes those lines.

Add the break-glass recipient from phase 1.1 to every rule now, so it is a
recipient on everything from here on.

Then re-encrypt:

```sh
for f in $(git ls-files | grep -E '\.enc(\.[a-z]+)?$'); do
  sops updatekeys -y "$f"
done
```

This rewrites only the wrapped data key in each file's `sops:` metadata. No
secret value changes, and you are never shown one.

**Verify** - every file should now carry the age recipients its rule names:

```sh
for f in $(git ls-files | grep -E '\.enc(\.[a-z]+)?$'); do
  printf '%-58s pgp=%s age=%s\n' "$f" \
    "$(grep -c '7EFF0CEC' "$f")" "$(grep -cE 'recipient"?[=:] ?"?age1' "$f")"
done
```

A file matching no rule makes `updatekeys` fail loudly rather than silently
producing something undecryptable - which is why the moves in phase 2 come
first.

Commit.


---

## Phase 4 - make the hosts decrypt with age

Three files set sops key material today:

- `hosts/bastion/wireguard.nix` lines 15-19
- `hosts/mucie/wireguard.nix` lines 12-16
- `home-manager/sops/default.nix` line 29

In the two host files, delete the whole `gnupg` block and the
`age.sshKeyPaths = [ ]` line. The NixOS and darwin defaults are already
`age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ]`, which is what you
want, so removing the overrides is the entire change.

In `home-manager/sops/default.nix`, replace the gnupg line with the
workstation key:

```nix
sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
```

Deploy one host at a time.

```sh
sudo darwin-rebuild switch --flake .        # mucie
```

**Verify on mucie:** `ls -l ~/.config/aerc/*.password` shows fresh timestamps
and the files are non-empty.

```sh
/nix/store/.../bin/deploy .#bastion         # bastion
ssh bastion sudo systemctl restart sops-install-secrets.service
ssh bastion sudo ls -l /run/secrets/
```

**Verify on bastion, and do not skip this:** reboot it and confirm decryption
works with no user present.

```sh
ssh bastion sudo reboot
# wait, then:
ssh bastion 'systemctl is-active dovecot2 rspamd nginx; sudo ls /run/secrets/'
```

All three services active and `/run/secrets` populated means bastion no longer
needs the PGP key. If it fails, the PGP key is still a recipient and still in
`/root/.gnupg`, so putting the `gnupg` block back restores the old behaviour.

---

## Phase 5 - sign commits with ssh instead of PGP

In `config/default.nix`, `gpgSigningKey` currently holds a PGP fingerprint.
Replace it with the path to your ssh public key, and rename it - the name is
about to be wrong. It is read in `home-manager/git/default.nix` at lines 16
and 66.

In `home-manager/git/default.nix`:

```nix
signing = {
  format = "ssh";
  key = "${config.home.homeDirectory}/.ssh/id_ed25519.pub";
  signByDefault = true;
};
```

Delete the `services.gpg-agent` block below it - it exists only to prompt for
the PGP signing passphrase.

On GitHub: **Settings -> SSH and GPG keys -> New SSH key**, and set
**Key type: Signing Key**. This is a second entry for the same key even if you
have already added it for authentication; GitHub treats auth and signing keys
separately and will not verify commits otherwise.

For local `git verify-commit`, point git at an allowed-signers file:

```nix
programs.git.extraConfig.gpg.ssh.allowedSignersFile =
  "${config.home.homeDirectory}/.config/git/allowed_signers";
```

with one line per key: `h.georgiev@hotmail.com ssh-ed25519 AAAA...`

**Verify:**

```sh
git commit --allow-empty -m "ssh signing test"
git log -1 --format='%G? %GS'      # expect: G <your key>
```

Push it and confirm GitHub shows **Verified**. Only then remove the PGP key
from your GitHub account.

---

## Phase 6 - retire the shared id_rsa

`os/linux/user.nix` line 19 lists one 2048-bit RSA key, the one copied to every
machine. Root's `authorized_keys` on bastion is not managed by this repository
at all and has drifted to two keys.

1. Add every new per-device ed25519 public key to
   `openssh.authorizedKeys.keys`, keeping the RSA key for now.
2. Bring root's list under nix as well, so it is reviewable:
   `users.users.root.openssh.authorizedKeys.keys = [ ... ]`.
3. Deploy every host.
4. From each device, confirm `ssh -i ~/.ssh/id_ed25519 <host>` works.
5. Only then remove the RSA entry, redeploy, and delete `~/.ssh/id_rsa*` from
   every machine.

Do bastion last and keep the DigitalOcean console open.

---

## Phase 7 - remove PGP

Only after phases 3 and 5 are proven.

1. Delete every `pgp:` line from `.sops.yaml`.
2. Re-encrypt to the age-only recipient set:

```sh
for f in $(git ls-files | grep -E '\.enc(\.[a-z]+)?$'); do sops updatekeys -y "$f"; done
```

3. **Verify before deleting any key material:**

```sh
for f in $(git ls-files | grep -E '\.enc(\.[a-z]+)?$'); do
  printf '%-60s pgp=%s\n' "$f" "$(grep -c 7EFF0CEC "$f")"
done
```

Every line must read `pgp=0`. Deploy all hosts and reboot bastion once more.

4. Delete the keys:

```sh
ssh bastion 'sudo gpg --homedir /root/.gnupg --delete-secret-and-public-key C8DDF8A8BDF70670'
ssh bastion 'sudo gpg --homedir /root/.gnupg --delete-secret-and-public-key 8D8E74E4033D192C'
```

The second one is your git signing key, which has no reason to be on bastion
and is a stale copy anyway - bastion's shows expired 2026-03-22 while yours
runs to 2027.

5. Remove `gnupg` from `home.packages` in `home-manager/sops/default.nix` if
   nothing else needs it, and remove the PGP key from your GitHub account.

---

## When you are done

```
no pgp: in .sops.yaml, and pgp=0 on all 15 files
no gnupg.home anywhere in the repository
bastion boots and serves mail with only its ssh host key
commits show Verified on GitHub, signed by ssh
~/.ssh/id_rsa gone from every machine
secrets/ gone from the repo root, and from .gitignore
```

Blast radius afterwards: bastion holds a key that decrypts bastion's secrets.
Not the Hetzner token, not mucie's WireGuard key, not lucie's litellm key.

## If something goes wrong

Every phase before 7 leaves the PGP key a valid recipient, so the recovery is
always the same: restore the `gnupg` block in the host file, deploy, and the
old path works again. That is why phase 7 comes last and why the verification
in step 3 of it matters more than any other check in this guide.

The break-glass key is the backstop if you lose a workstation mid-migration.
It can decrypt every file, from any machine, with:

```sh
SOPS_AGE_KEY='AGE-SECRET-KEY-1...' sops -d <file>
```
