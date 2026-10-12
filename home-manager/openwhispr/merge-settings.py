"""Merge managed preferences into OpenWhispr 1.10.2's writable storage."""

import json
import os
import re
import shutil
import sys
import tempfile
import time
from pathlib import Path

import plyvel

PREFIX = b"_file://\x00"


def encode_string(value):
    try:
        return b"\x01" + value.encode("latin1")
    except UnicodeEncodeError:
        return b"\x00" + value.encode("utf-16-le")


def storage_value(value):
    return (
        value
        if isinstance(value, str)
        else json.dumps(value, ensure_ascii=False, separators=(",", ":"))
    )


def varint(value):
    result = bytearray()
    while value > 127:
        result.append((value & 127) | 128)
        value >>= 7
    result.append(value)
    return bytes(result)


def merge_environment(existing, settings):
    remaining = dict(settings)
    lines = []
    for line in existing.splitlines(keepends=True):
        match = re.match(r"\s*(?:export\s+)?([A-Za-z_][A-Za-z_0-9]*)\s*=", line)
        key = match[1] if match else None
        if key in settings:
            if key in remaining:
                lines.append(f"{key}={remaining.pop(key)}\n")
        else:
            lines.append(line)
    if remaining and lines and not lines[-1].endswith("\n"):
        lines.append("\n")
    lines.extend(f"{key}={value}\n" for key, value in remaining.items())
    return "".join(lines)


def quote_environment(value):
    if value == value.strip() and not any(char in value for char in "#\"'`"):
        return value
    for quote in ("'", '"', "`"):
        if quote not in value and not (
            quote == '"' and ("\\n" in value or "\\r" in value)
        ):
            return quote + value + quote
    raise ValueError("Environment value cannot be represented as a single dotenv line.")


def merge(settings, data_dir, backup_dir):
    os.umask(0o077)
    # Chromium holds this lock even before opening localStorage.
    if (data_dir / "SingletonLock").is_symlink() or (
        data_dir / "SingletonLock"
    ).exists():
        raise RuntimeError(
            "Quit OpenWhispr, then run Home Manager activation again (SingletonLock exists)."
        )

    environment = settings["environment"]
    for key, value in environment.items():
        if (
            not re.fullmatch(r"[A-Z_][A-Z_0-9]*", key)
            or not isinstance(value, str)
            or "\n" in value
            or "\r" in value
        ):
            raise ValueError(f"Invalid environment setting: {key}")

    env_path = data_dir / ".env"
    old_env = env_path.read_text() if env_path.exists() else ""
    new_env = merge_environment(
        old_env, {key: quote_environment(value) for key, value in environment.items()}
    )
    entries = {
        PREFIX + encode_string(key): encode_string(storage_value(value))
        for key, value in settings["localStorage"].items()
    }
    db_path = data_dir / "Local Storage" / "leveldb"
    db_path.parent.mkdir(parents=True, exist_ok=True)
    try:
        db = plyvel.DB(str(db_path), create_if_missing=True)
    except plyvel.Error as error:
        raise RuntimeError(
            "Cannot open OpenWhispr localStorage. Quit OpenWhispr and retry."
        ) from error

    with db:
        version = db.get(b"VERSION")
        if version not in (None, b"1") or (
            version is None and next(db.iterator(), None) is not None
        ):
            raise RuntimeError(
                "Unsupported Chromium localStorage schema; settings were not changed."
            )
        changed = {key: value for key, value in entries.items() if db.get(key) != value}
        if not changed and old_env == new_env:
            print("OpenWhispr settings are already up to date.")
            return

        backup_dir.mkdir(parents=True, exist_ok=True)
        backup = Path(
            tempfile.mkdtemp(prefix=time.strftime("%Y%m%d-%H%M%S-"), dir=backup_dir)
        )
        with (
            plyvel.DB(str(backup / "leveldb"), create_if_missing=True) as saved,
            saved.write_batch(sync=True) as batch,
        ):
            for key, value in db:
                batch.put(key, value)
        if env_path.exists():
            shutil.copyfile(env_path, backup / ".env")

        if changed:
            items = dict(db.iterator(prefix=PREFIX))
            items.update(changed)
            size = sum(
                len(key) - len(PREFIX) + len(value) for key, value in items.items()
            )
            # Chromium metadata is protobuf; its clock counts microseconds since 1601.
            timestamp = time.time_ns() // 1000 + 11644473600000000
            with db.write_batch(sync=True) as batch:
                batch.put(b"VERSION", b"1")
                for key, value in changed.items():
                    batch.put(key, value)
                batch.put(
                    b"META:file://",
                    b"\x08" + varint(timestamp) + b"\x10" + varint(size),
                )
                batch.put(b"METAACCESS:file://", b"\x08" + varint(timestamp))

        if new_env != old_env:
            fd, temporary = tempfile.mkstemp(prefix=".env-home-manager-", dir=data_dir)
            try:
                with os.fdopen(fd, "w") as handle:
                    handle.write(new_env)
                os.replace(temporary, env_path)
            finally:
                Path(temporary).unlink(missing_ok=True)
        print(f"Applied OpenWhispr settings. Backup: {backup}")


if __name__ == "__main__":
    try:
        merge(
            json.loads(Path(sys.argv[1]).read_text()),
            Path(sys.argv[2]),
            Path(sys.argv[3]),
        )
    except (RuntimeError, ValueError, OSError) as error:
        sys.exit(f"OpenWhispr: {error}")
