"""Merge the Nix-generated Codex settings into a writable ~/.codex/config.toml.

Codex persists project trust decisions ([projects] tables) into the same file
it reads its settings from, so that file cannot be a /nix/store symlink - the
store is read-only and the write fails with a -32603. Nix owns the tables named
in the generated file; everything else in the target is left exactly as Codex
wrote it.
"""

import os
import sys
import tomllib

import tomli_w

generated_path, target_path = sys.argv[1], sys.argv[2]

with open(generated_path, "rb") as handle:
    generated = tomllib.load(handle)

# A symlink here is the previous generation's home.file entry pointing into the
# store. Drop it rather than following it, which would write to the store.
existing = {}
if os.path.islink(target_path):
    os.unlink(target_path)
elif os.path.exists(target_path):
    with open(target_path, "rb") as handle:
        existing = tomllib.load(handle)

merged = dict(existing)
for key, value in generated.items():
    # An empty table means the toggles that feed it are all off, so the key
    # should disappear rather than linger as a stale empty section. Only empty
    # tables are pruned: `false` and `0` are values Nix means to set, not
    # absence, and sandbox_workspace_write.network_access is exactly that.
    if isinstance(value, dict) and not value:
        merged.pop(key, None)
    else:
        merged[key] = value

os.makedirs(os.path.dirname(target_path), exist_ok=True)
tmp_path = target_path + ".nix-tmp"
with open(tmp_path, "wb") as handle:
    tomli_w.dump(merged, handle)
os.replace(tmp_path, target_path)
