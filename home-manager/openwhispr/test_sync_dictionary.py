import importlib.util
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import Mock, patch

spec = importlib.util.spec_from_file_location(
    "sync_dictionary", Path(__file__).with_name("sync-dictionary.py")
)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class DictionaryTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.bridge = Path(temporary.name) / "cli-bridge.json"
        self.bridge.write_text(
            json.dumps({"version": 1, "port": 12345, "token": "test-token"})
        )
        self.connection = Mock()
        patcher = patch.object(
            module.http.client, "HTTPConnection", return_value=self.connection
        )
        self.factory = patcher.start()
        self.addCleanup(patcher.stop)

    def respond(self, *data, status=200):
        self.connection.getresponse.side_effect = [
            Mock(status=status, read=Mock(return_value=json.dumps({"data": item})))
            for item in data
        ]

    def test_additive_and_idempotent(self):
        self.respond(["OpenWhispr", "LearnedWord"], {"added": 2})
        self.assertEqual(module.sync(["NixOS", "nixos", " Jem "], self.bridge), 2)
        self.factory.assert_called_with("127.0.0.1", 12345, timeout=5)
        update = self.connection.request.call_args
        self.assertEqual(update.args, ("POST", "/v1/dictionary/update"))
        self.assertEqual(
            json.loads(update.kwargs["body"]), {"add": ["NixOS", "Jem"], "remove": []}
        )
        self.assertEqual(update.kwargs["headers"]["Authorization"], "Bearer test-token")
        self.connection.reset_mock()
        self.respond(["OpenWhispr", "LearnedWord", "NixOS", "Jem"])
        self.assertEqual(module.sync(["NixOS", "Jem"], self.bridge), 0)
        self.connection.request.assert_called_once()
        self.connection.close.assert_called_once()

    def test_closed_app(self):
        self.bridge.unlink()
        self.assertEqual(module.sync(["NixOS"], self.bridge), 0)
        self.factory.assert_not_called()

    def test_stale_descriptor(self):
        self.connection.request.side_effect = ConnectionRefusedError
        self.assertEqual(module.sync(["NixOS"], self.bridge), 0)
        self.connection.close.assert_called_once()

    def test_api_error_is_not_silenced(self):
        self.respond({}, status=401)
        with self.assertRaisesRegex(RuntimeError, "401"):
            module.sync(["NixOS"], self.bridge)
        self.connection.request.assert_called_once()

    def test_unknown_bridge_version(self):
        self.bridge.write_text(json.dumps({"version": 2}))
        with self.assertRaisesRegex(ValueError, "version"):
            module.sync(["NixOS"], self.bridge)
        self.factory.assert_not_called()


if __name__ == "__main__":
    unittest.main()
