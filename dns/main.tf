# DNS for the zones in this directory, applied to Hetzner with OpenTofu.
#
# Run it with `nix run .#dns -- plan` / `-- apply`, which decrypts the API
# token into HCLOUD_TOKEN for the length of the run. See README-dns.md.
#
# Records live in one file per zone; this file holds only the machinery that
# turns them into resources.

terraform {
  required_version = ">= 1.7"

  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
      # Pinned by nix rather than fetched from the registry - the version here
      # only has to agree with terraform-providers.hetznercloud_hcloud.
      version = "~> 1.68"
    }
  }
}

provider "hcloud" {
  # Reads HCLOUD_TOKEN from the environment.
}

locals {
  # One entry per zone file in this directory.
  zones = {
    "hgeorgiev.com" = local.hgeorgiev_com
    "dissona.app"   = local.dissona_app
    "snugbg.org"    = local.snugbg_org
    "unak-loko.org" = local.unak_loko_org
  }

  # Flatten to "<zone>/<name>/<type>" => rrset. That key is exactly the id the
  # provider imports by, which is what lets the import block below be written
  # once for everything rather than once per record.
  rrsets = merge([
    for zone, records in local.zones : {
      for key, rr in records :
      "${zone}/${key}" => {
        zone    = zone
        name    = split("/", key)[0]
        type    = split("/", key)[1]
        ttl     = rr.ttl
        records = rr.records
        # Hetzner keeps a free-text comment per record. It is console-side
        # metadata and never appears in a DNS answer, but it round-trips, so
        # carry it rather than have every plan offer to delete it.
        comment = try(rr.comment, null)
      }
    }
  ]...)
}

resource "hcloud_zone_rrset" "this" {
  for_each = local.rrsets

  zone = each.value.zone
  name = each.value.name
  type = each.value.type
  ttl  = each.value.ttl

  records = [
    for value in each.value.records : {
      value   = value
      comment = each.value.comment
    }
  ]
}

# Rebuilding a lost state file, rather than a normal apply. Off by default:
# an import block names a record that must already exist in Hetzner, so
# leaving it on would turn every newly declared record into an attempt to
# import something that is not there yet, and fail.
#
#   nix run .#dns -- apply -var adopt=true
#
# adopts every declared record instead of creating it, which is what makes
# terraform.tfstate disposable and so not worth committing. It expects config
# and Hetzner to already agree; a record declared here but absent there still
# has to be created by a normal apply first.
variable "adopt" {
  description = "Import every declared record rather than creating it, to rebuild lost state."
  type        = bool
  default     = false
}

import {
  for_each = var.adopt ? local.rrsets : {}

  to = hcloud_zone_rrset.this[each.key]
  id = each.key
}
