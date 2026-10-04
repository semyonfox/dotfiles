import importlib
import io
import sys
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch


with patch.dict(sys.modules, {"tiktoken": None}):
    benchmark = importlib.import_module("skills.compress.scripts.benchmark")


class BenchmarkPairTests(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp_dir.cleanup)
        self.original = Path(self.temp_dir.name) / "original.md"
        self.compressed = Path(self.temp_dir.name) / "compressed.md"

    def test_empty_original_reports_na(self):
        self.original.write_text("")
        self.compressed.write_text("")

        row = benchmark.benchmark_pair(self.original, self.compressed)
        output = io.StringIO()
        with redirect_stdout(output):
            benchmark.print_table([row])

        self.assertEqual(row[:3], ("compressed.md", 0, 0))
        self.assertIsNone(row[3])
        self.assertIn("| n/a |", output.getvalue())

    def test_nonempty_original_keeps_numeric_percentage(self):
        self.original.write_text("one two three four")
        self.compressed.write_text("one two")

        row = benchmark.benchmark_pair(self.original, self.compressed)
        output = io.StringIO()
        with redirect_stdout(output):
            benchmark.print_table([row])

        self.assertEqual(row[3], 50.0)
        self.assertIn("| 50.0% |", output.getvalue())


if __name__ == "__main__":
    unittest.main()
