import os
import pathlib
import plistlib
import subprocess
import tempfile
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]


class InstallBundleTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = pathlib.Path(self.temp.name)
        self.source = self.root / 'download/VietLunar.app'
        self.destination = self.root / 'Applications/VietLunar.app'
        self.bundle(self.source, 'new')
        self.bundle(self.destination, 'old')

    def bundle(self, path, marker, identifier='com.bravohex.vietlunar'):
        (path / 'Contents/MacOS').mkdir(parents=True)
        (path / 'Contents/Info.plist').write_bytes(plistlib.dumps({
            'CFBundleIdentifier': identifier, 'CFBundleExecutable': 'VietLunar'}))
        executable = path / 'Contents/MacOS/VietLunar'
        executable.write_text(marker)
        executable.chmod(0o755)

    def run_install(self, source=None, env=None):
        return subprocess.run(['bash', str(ROOT / 'scripts/install_bundle.sh'),
                               str(source or self.source), str(self.destination)],
                              env=env, capture_output=True, text=True)

    def marker(self):
        return (self.destination / 'Contents/MacOS/VietLunar').read_text()

    def test_replaces_valid_bundle(self):
        result = self.run_install()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.marker(), 'new')

    def test_same_path_and_alias_preserve_source(self):
        alias = self.root / 'alias.app'
        alias.symlink_to(self.destination, target_is_directory=True)
        for source in (self.destination, alias):
            result = self.run_install(source)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('same', result.stderr)
            self.assertEqual(self.marker(), 'old')

    def test_copy_failure_preserves_previous_install(self):
        binary = self.root / 'bin'
        binary.mkdir()
        stub = binary / 'ditto'
        stub.write_text('#!/bin/sh\nexit 9\n')
        stub.chmod(0o755)
        env = dict(os.environ, PATH=str(binary) + os.pathsep + os.environ['PATH'])
        self.assertNotEqual(self.run_install(env=env).returncode, 0)
        self.assertEqual(self.marker(), 'old')
        self.assertEqual(list(self.destination.parent.glob('.VietLunar-install.*')), [])

    def test_promotion_failure_restores_previous_install(self):
        binary = self.root / 'bin'
        binary.mkdir()
        stub = binary / 'mv'
        stub.write_text('#!/bin/sh\ncase "$1" in */new.app) exit 9;; esac\nexec /bin/mv "$@"\n')
        stub.chmod(0o755)
        env = dict(os.environ, PATH=str(binary) + os.pathsep + os.environ['PATH'])
        self.assertNotEqual(self.run_install(env=env).returncode, 0)
        self.assertEqual(self.marker(), 'old')

    def test_rejects_invalid_source_without_touching_install(self):
        (self.source / 'Contents/Info.plist').write_bytes(plistlib.dumps({'CFBundleIdentifier': 'other.app'}))
        self.assertNotEqual(self.run_install().returncode, 0)
        self.assertEqual(self.marker(), 'old')


if __name__ == '__main__':
    unittest.main()
