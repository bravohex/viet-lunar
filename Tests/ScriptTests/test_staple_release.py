import os
import pathlib
import subprocess
import tempfile
import textwrap
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]


class StapleReleaseTests(unittest.TestCase):
    def run_step(self, mode='success', stage='validate'):
        with tempfile.TemporaryDirectory(prefix='stapler test ') as directory:
            root = pathlib.Path(directory)
            binary = root / 'bin'
            binary.mkdir()
            stubs = {
                'xcrun': '''#!/bin/bash
set -eu
[[ "$1" == stapler ]]
[[ "$3" == "$RUNNER_TEMP/VietLunar.xcarchive/Products/Applications/VietLunar.app" ]]
echo "$2" >> "$RUNNER_TEMP/calls"
count_file="$RUNNER_TEMP/$2.count"
count=0
[[ ! -f "$count_file" ]] || count=$(cat "$count_file")
count=$((count + 1))
echo "$count" > "$count_file"
if [[ "$2" == "$FAIL_STAGE" ]]; then
  case "$TEST_MODE" in
    transient) [[ "$count" -gt 1 ]] && exit 0 ;;
    persistent) ;;
    invalid) echo 'The validate action failed! Error 68.' >&2; exit 68 ;;
    tls) echo 'Error Domain=NSURLErrorDomain Code=-1202 certificate untrusted' >&2; exit 68 ;;
    *) exit 0 ;;
  esac
  echo 'error is Error Domain=NSURLErrorDomain Code=-1005 "The network connection was lost."' >&2
  exit 68
fi
''',
                'spctl': '''#!/bin/bash
echo assess >> "$RUNNER_TEMP/calls"
[[ "$TEST_MODE" != rejected ]] || exit 3
''',
                'sleep': '#!/bin/bash\necho "sleep $1" >> "$RUNNER_TEMP/calls"\n',
            }
            for name, source in stubs.items():
                path = binary / name
                path.write_text(source)
                path.chmod(0o755)
            workflow = (ROOT / '.github/workflows/release.yml').read_text()
            step = workflow.split('      - name: Staple and assess notarized app\n', 1)[1]
            step = step.split('\n      - name:', 1)[0].split('        run: |\n', 1)[1]
            result = subprocess.run(
                ['bash', '-e', '-o', 'pipefail', '-c', textwrap.dedent(step)],
                cwd=ROOT, capture_output=True, text=True, timeout=10,
                env=dict(os.environ, PATH=str(binary) + os.pathsep + os.environ['PATH'],
                         RUNNER_TEMP=directory, TEST_MODE=mode, FAIL_STAGE=stage))
            calls = (root / 'calls').read_text().splitlines()
            return result, calls

    def test_success_still_requires_gatekeeper(self):
        result, calls = self.run_step()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls, ['staple', 'validate', 'assess'])

    def test_connection_loss_retries_only_failed_operation(self):
        for stage, expected in (
            ('validate', ['staple', 'validate', 'sleep 10', 'validate', 'assess']),
            ('staple', ['staple', 'sleep 10', 'staple', 'validate', 'assess']),
        ):
            with self.subTest(stage=stage):
                result, calls = self.run_step('transient', stage)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(calls, expected)

    def test_connection_loss_eventually_fails_and_skips_assessment(self):
        result, calls = self.run_step('persistent')
        self.assertEqual(result.returncode, 68)
        self.assertEqual(calls, ['staple', 'validate', 'sleep 10', 'validate',
                                 'sleep 20', 'validate', 'sleep 40', 'validate'])

    def test_invalid_ticket_and_tls_failure_do_not_retry(self):
        for mode in ('invalid', 'tls'):
            with self.subTest(mode=mode):
                result, calls = self.run_step(mode)
                self.assertEqual(result.returncode, 68)
                self.assertEqual(calls, ['staple', 'validate'])

    def test_gatekeeper_rejection_is_fatal(self):
        result, calls = self.run_step('rejected')
        self.assertEqual(result.returncode, 3)
        self.assertEqual(calls, ['staple', 'validate', 'assess'])
