import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from skills.compress.scripts import compress


class CompressFileTests(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp_dir.cleanup)
        self.filepath = Path(self.temp_dir.name) / "memory.md"
        self.original = b"# Keep\nhttps://example.com\n"
        self.filepath.write_bytes(self.original)
        self.backup = self.filepath.with_name("memory.original.md")

    def test_failed_repair_leaves_input_and_backup_unchanged(self):
        with patch.object(compress, "call_claude", side_effect=["bad", RuntimeError("repair failed")]):
            with self.assertRaisesRegex(RuntimeError, "repair failed"):
                compress.compress_file(self.filepath)

        self.assertEqual(self.filepath.read_bytes(), self.original)
        self.assertFalse(self.backup.exists())

    def test_validation_failure_leaves_input_and_backup_unchanged(self):
        with patch.object(compress, "call_claude", side_effect=["bad", "still bad"]):
            self.assertFalse(compress.compress_file(self.filepath))

        self.assertEqual(self.filepath.read_bytes(), self.original)
        self.assertFalse(self.backup.exists())

    def test_success_preserves_original_bytes_and_file_mode(self):
        self.filepath.chmod(0o640)
        old_mtime = 1_600_000_000_000_000_000
        os.utime(self.filepath, ns=(old_mtime, old_mtime))
        with patch.object(compress, "call_claude", return_value="# Keep\nshort https://example.com\n"):
            self.assertTrue(compress.compress_file(self.filepath))

        self.assertEqual(self.backup.read_bytes(), self.original)
        self.assertEqual(self.filepath.read_text(), "# Keep\nshort https://example.com\n")
        self.assertEqual(self.filepath.stat().st_mode & 0o777, 0o640)
        self.assertGreater(self.filepath.stat().st_mtime_ns, old_mtime)
        self.assertEqual(self.backup.stat().st_mode & 0o777, 0o640)

    def test_source_edit_during_model_call_is_not_overwritten(self):
        updated = b"# Latest\nhttps://example.com\n"

        def edit_source(_prompt):
            self.filepath.write_bytes(updated)
            return "# Keep\nshort https://example.com\n"

        with patch.object(compress, "call_claude", side_effect=edit_source):
            with self.assertRaisesRegex(RuntimeError, "File changed during compression"):
                compress.compress_file(self.filepath)

        self.assertEqual(self.filepath.read_bytes(), updated)
        self.assertFalse(self.backup.exists())

    def test_failed_replace_leaves_original_and_removes_new_backup(self):
        with patch.object(compress, "call_claude", return_value="# Keep\nshort https://example.com\n"):
            with patch.object(compress.os, "replace", side_effect=OSError("replace failed")):
                with self.assertRaisesRegex(OSError, "replace failed"):
                    compress.compress_file(self.filepath)

        self.assertEqual(self.filepath.read_bytes(), self.original)
        self.assertFalse(self.backup.exists())

    def test_invalid_utf8_is_rejected_before_model_call(self):
        invalid_bytes = self.original + b"\xff"
        self.filepath.write_bytes(invalid_bytes)
        with patch.object(compress, "call_claude") as call:
            with self.assertRaises(UnicodeDecodeError):
                compress.compress_file(self.filepath)

        call.assert_not_called()
        self.assertEqual(self.filepath.read_bytes(), invalid_bytes)
        self.assertFalse(self.backup.exists())

    def test_existing_backup_is_preserved(self):
        self.backup.write_bytes(b"existing backup")
        with patch.object(compress, "call_claude") as call:
            self.assertFalse(compress.compress_file(self.filepath))

        call.assert_not_called()
        self.assertEqual(self.filepath.read_bytes(), self.original)
        self.assertEqual(self.backup.read_bytes(), b"existing backup")


if __name__ == "__main__":
    unittest.main()
