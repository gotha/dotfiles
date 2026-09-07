# DNS

DNS records live in `./dns` and are applied to Hetzner with
[OpenTofu](https://opentofu.org/) and the official
[`hetznercloud/hcloud`](https://github.com/hetznercloud/terraform-provider-hcloud)
provider. The repository is the source of truth for the records it declares:
editing one of those in the Hetzner console is reverted on the next apply.

The unit of ownership is the rrset, not the record. Add a second value to a
declared `www/A` and the next apply strips it back; add a `blog/A` that no file
mentions and OpenTofu neither manages nor deletes it, unlike octoDNS which
removes anything absent from its source. The `SOA` records are the standing
example of the latter.

`tofu plan` cannot show you that second kind - it compares state against
config, and a console-created rrset is in neither. Spotting one means looking
at the zone in the Hetzner console.

Hetzner shut down the old DNS console and its API (`dns.hetzner.com/api/v1`)
in May 2026 and folded DNS into the Cloud API. `octodns-hetzner` still targets
the old endpoint and does not work, which is why this is OpenTofu rather than
octoDNS.

## One-time: the API token

Create a token in the Hetzner console and store it with sops:

```sh
sops secrets/hetzner-dns.enc.json
```

An editor opens on a new file. It holds one key:

```json
{
  "token": "<the token>"
}
```

The catch-all rule in `.sops.yaml` encrypts it to the same PGP key as every
other secret here. Note `.gitignore` has `secrets/*`, so like the others it
needs `git add -f` to be tracked.

## Plan and apply

```sh
# show what would change - reads Hetzner, writes nothing
nix run .#dns

# apply it
nix run .#dns -- apply
```

Arguments pass straight through to `tofu`, so `nix run .#dns -- state list`
and friends work too. Both must run from the repository root.

## Adding a record

Edit the zone's file in `dns/`. Each entry is keyed `"<name>/<type>"`, the apex
is `@`, and `records` is a list of values:

```hcl
"www/A"    = { ttl = 60, records = ["192.0.2.1"] }
"@/MX"     = { ttl = 60, records = ["10 mail.example.com."] }
"docs/TXT" = { ttl = 60, records = ["\"hello\""] }
```

TXT values must arrive at the API already quoted, and anything over 255
characters has to be split into several adjacent quoted strings - see the DKIM
records for what that looks like. An optional `comment` on an entry becomes
Hetzner's console-side note for those records; it never appears in a DNS answer.

A new zone needs a file in `dns/` holding a `locals` block and an entry in the
`zones` map at the top of `dns/main.tf`.

## State is disposable

`terraform.tfstate` is not committed - this repository is public, and it does
not need to be. To rebuild it from the live zones:

```sh
nix run .#dns -- apply -var adopt=true
```

That turns on the `import` block in `dns/main.tf`, which adopts every declared
record instead of creating it, and should report "N to import, 0 to add,
0 to change, 0 to destroy".

It is off by default, and has to be: an import block names a record that must
already exist at Hetzner, so leaving it on would turn every newly declared
record into an attempt to import something that is not there yet. `adopt=true`
therefore expects config and Hetzner to already agree - a record declared here
but absent there still has to be created by a normal apply first.

## Two things to know

The apex `NS` records are managed like any other. They match what each zone is
delegated to today; changing them changes the delegation.

`SOA` is deliberately absent from the zone files. The API owns it and bumps its
serial, and the provider treats it as a special case, so leaving it out keeps
it from appearing in every plan.
