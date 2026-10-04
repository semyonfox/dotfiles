"""Bounded tests for the backup status and retention block; never run the backup script."""

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parents[1] / "server/.local/bin/server-nas-restic"
if len(sys.argv) > 1:
    del sys.argv[1]


def source_block(source: str) -> str:
    start = source.index('if [ "$rc" -eq 3 ]')
    final_line = "  --keep-daily 14 --keep-weekly 8 --keep-monthly 12 --keep-yearly 3"
    end = source.index(final_line, start) + len(final_line)
    return source[start:end]


class BackupControlFlowTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.source = SCRIPT.read_text()
        cls.block = source_block(cls.source)

    def run_block(self, backup_status: int) -> tuple[subprocess.CompletedProcess[str], str]:
        with tempfile.TemporaryDirectory() as temp_dir:
            calls = Path(temp_dir) / "restic-calls"
            shell = (
                "set -euo pipefail\n"
                "restic_stub() { printf '%s\\n' \"$1\" >> \"$CALLS_FILE\"; }\n"
                f"rc={backup_status}\n"
                "RESTIC=restic_stub\nhost=test-host\nTAG=server-home\n"
                f"{self.block}\n"
            )
            result = subprocess.run(
                ["bash", "-c", shell],
                capture_output=True,
                text=True,
                check=False,
                env={"PATH": "/usr/bin:/bin", "CALLS_FILE": str(calls)},
                cwd=temp_dir,
            )
            return result, calls.read_text() if calls.exists() else ""

    def test_partial_backup_fails_without_retention(self) -> None:
        result, calls = self.run_block(3)
        self.assertEqual(result.returncode, 3)
        self.assertIn("skipping retention", result.stderr)
        self.assertEqual(calls, "")

    def test_complete_backup_runs_retention(self) -> None:
        result, calls = self.run_block(0)
        self.assertEqual(result.returncode, 0)
        self.assertEqual(calls, "forget\n")

    def test_fatal_backup_fails_without_retention(self) -> None:
        result, calls = self.run_block(1)
        self.assertEqual(result.returncode, 1)
        self.assertEqual(calls, "")

    def test_stage_system_exists_before_optional_skip_record(self) -> None:
        stage = self.source.index('stage="$(mktemp -d /var/tmp/server-recovery.XXXXXX)"')
        self.assertTrue(
            'mkdir -p "$stage/system"' in self.source[stage:],
            "stage/system directory is not initialized",
        )
        create_system = self.source.index('mkdir -p "$stage/system"', stage)
        inspect_paths = self.source.index("for path in /etc/fstab", stage)
        self.assertLess(create_system, inspect_paths)


if __name__ == "__main__":
    unittest.main()
