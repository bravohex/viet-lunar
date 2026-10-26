import pathlib
import plistlib
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]


class ReleaseEntitlementsTests(unittest.TestCase):
    def verify(self, entitlements):
        with tempfile.TemporaryDirectory() as directory:
            path = pathlib.Path(directory) / 'entitlements.plist'
            path.write_bytes(plistlib.dumps(entitlements))
            return subprocess.run(
                ['python3', str(ROOT / 'scripts/verify_release_entitlements.py'), str(path)],
                capture_output=True, text=True,
            )

    def test_accepts_sandboxed_release(self):
        self.assertEqual(self.verify({'com.apple.security.app-sandbox': True}).returncode, 0)

    def test_rejects_missing_or_non_boolean_sandbox(self):
        self.assertNotEqual(self.verify({}).returncode, 0)
        for value in (False, 'true', 1):
            with self.subTest(value=value):
                self.assertNotEqual(self.verify({'com.apple.security.app-sandbox': value}).returncode, 0)

    def test_rejects_debug_and_network_access(self):
        for key in ('com.apple.security.get-task-allow', 'get-task-allow',
                    'com.apple.security.network.client', 'com.apple.security.network.server'):
            with self.subTest(key=key):
                result = self.verify({'com.apple.security.app-sandbox': True, key: True})
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(key, result.stderr)

    def test_accepts_explicitly_disabled_debug_access(self):
        self.assertEqual(self.verify({'com.apple.security.app-sandbox': True,
                                     'com.apple.security.get-task-allow': False}).returncode, 0)


if __name__ == '__main__':
    unittest.main()
