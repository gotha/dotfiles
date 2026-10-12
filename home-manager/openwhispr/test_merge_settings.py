import contextlib
import importlib.util
import io
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

import plyvel

spec = importlib.util.spec_from_file_location(
    "merge_settings", Path(__file__).with_name("merge-settings.py")
)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class MergeSettingsTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.data = self.root / "open-whispr"
        self.backups = self.root / "backups"
        self.settings = {
            "environment": {"DICTATION_KEY": "RightCommand"},
            "localStorage": {
                "dictationKey": "RightCommand",
                "audioCuesEnabled": True,
                "customPrompt.cleanup": "Здравей 👋",
            },
        }

    @property
    def db_path(self):
        return self.data / "Local Storage" / "leveldb"

    def apply(self):
        with contextlib.redirect_stdout(io.StringIO()):
            module.merge(self.settings, self.data, self.backups)

    def test_fresh_profile_and_idempotence(self):
        self.apply()
        with plyvel.DB(str(self.db_path)) as db:
            self.assertEqual(db.get(b"VERSION"), b"1")
            self.assertEqual(
                db.get(module.PREFIX + b"\x01audioCuesEnabled"), b"\x01true"
            )
            self.assertEqual(
                db.get(module.PREFIX + b"\x01customPrompt.cleanup"),
                b"\x00" + "Здравей 👋".encode("utf-16-le"),
            )
            self.assertIsNotNone(db.get(b"META:file://"))
            previous = dict(db)
        self.apply()
        with plyvel.DB(str(self.db_path)) as db:
            self.assertEqual(dict(db), previous)
        self.assertEqual(len(list(self.backups.iterdir())), 1)
        self.assertEqual((self.data / ".env").stat().st_mode & 0o777, 0o600)

    def test_preserves_unmanaged_data_and_backs_up_previous_values(self):
        self.db_path.parent.mkdir(parents=True)
        original_env = "# Keep me\nAPI_KEY=private-test-value\nexport DICTATION_KEY=Old\nDICTATION_KEY=Duplicate\nOTHER=value"
        (self.data / ".env").write_text(original_env)
        (self.data / "transcriptions.db").write_bytes(b"untouched")
        with plyvel.DB(str(self.db_path), create_if_missing=True) as db:
            db.put(b"VERSION", b"1")
            db.put(module.PREFIX + b"\x01dictationKey", b"\x01Old")
            db.put(module.PREFIX + b"\x01unmanaged", b"\x01keep")
            db.put(b"_https://example.org\x00\x01key", b"\x01keep")
            original_db = dict(db)
        self.apply()
        self.assertEqual(
            (self.data / ".env").read_text(),
            "# Keep me\nAPI_KEY=private-test-value\nDICTATION_KEY=RightCommand\nOTHER=value",
        )
        self.assertEqual((self.data / "transcriptions.db").read_bytes(), b"untouched")
        with plyvel.DB(str(self.db_path)) as db:
            self.assertEqual(db.get(module.PREFIX + b"\x01unmanaged"), b"\x01keep")
            self.assertEqual(db.get(b"_https://example.org\x00\x01key"), b"\x01keep")
        backup = next(self.backups.iterdir())
        self.assertEqual((backup / ".env").read_text(), original_env)
        self.assertEqual(backup.stat().st_mode & 0o777, 0o700)
        with plyvel.DB(str(backup / "leveldb")) as db:
            self.assertEqual(dict(db), original_db)

    def test_refuses_running_app_before_writing(self):
        self.data.mkdir()
        (self.data / "SingletonLock").symlink_to("hostname-12345")
        with self.assertRaisesRegex(RuntimeError, "Quit OpenWhispr"):
            self.apply()
        self.assertFalse(self.db_path.exists())
        self.assertFalse((self.data / ".env").exists())

    def test_respects_leveldb_lock(self):
        self.db_path.parent.mkdir(parents=True)
        settings_path = self.root / "settings.json"
        settings_path.write_text(json.dumps(self.settings))
        with plyvel.DB(str(self.db_path), create_if_missing=True):
            result = subprocess.run(
                [
                    sys.executable,
                    str(Path(module.__file__)),
                    str(settings_path),
                    str(self.data),
                    str(self.backups),
                ],
                capture_output=True,
                text=True,
                check=False,
            )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Quit OpenWhispr", result.stderr)
        self.assertFalse((self.data / ".env").exists())
        self.assertFalse(self.backups.exists())

    def test_refuses_unknown_schema(self):
        self.db_path.parent.mkdir(parents=True)
        with plyvel.DB(str(self.db_path), create_if_missing=True) as db:
            db.put(b"VERSION", b"999")
        with self.assertRaisesRegex(RuntimeError, "Unsupported"):
            self.apply()
        self.assertFalse((self.data / ".env").exists())
        self.assertFalse(self.backups.exists())

    def test_rejects_multiline_environment_value(self):
        self.settings["environment"]["DICTATION_KEY"] = "RightCommand\nOTHER=bad"
        with self.assertRaises(ValueError):
            self.apply()
        self.assertFalse(self.data.exists())

    def test_environment_preserves_hashes_spaces_and_literal_backslashes(self):
        self.settings["environment"] = {
            "CUSTOM_ENDPOINT": "https://example.org/#fragment",
            "WHISPER_MODEL": "  spaced model  ",
            "EXAMPLE": r"literal\nvalue",
        }
        self.apply()
        self.assertEqual(
            (self.data / ".env").read_text(),
            "CUSTOM_ENDPOINT='https://example.org/#fragment'\n"
            "WHISPER_MODEL='  spaced model  '\n"
            "EXAMPLE=literal\\nvalue\n",
        )


if __name__ == "__main__":
    unittest.main()
