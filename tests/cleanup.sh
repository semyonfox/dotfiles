#!/usr/bin/env bash
# Integration suite replaces obsolete tests that expected unsafe raw deletion.
set -euo pipefail
repo="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
exec python3 -B "$repo/tests/cleanup.py"
