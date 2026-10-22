#!/usr/bin/env python3
"""No privileged commands: updater branch tests with a private mocked PATH."""
import os
from pathlib import Path
import subprocess
import tempfile

repo = Path(__file__).resolve().parents[1]
script = repo / 'home/.local/bin/update-amp'
with tempfile.TemporaryDirectory(dir=os.environ.get('TMPDIR')) as tmp:
    p = Path(tmp)
    trace = p / 'trace'
    def mock(name, body):
        f = p / name
        f.write_text('#!/bin/sh\n'+body+'\n')
        f.chmod(0o755)
    mock('uname', 'printf "%s\\n" "${MOCK_OS:-Linux}"')
    mock('ampinstmgr', 'exit 0')
    mock('dpkg-query', '[ "${CASE:-}" != owner-mismatch ] || exit 1; printf "ampinstmgr: %s\\n" "$2"')
    mock('apt-get', 'exit 90')
    mock('grep', 'while read -r line; do case "$line" in ampinstmgr:*) exit 0;; esac; done; exit 1')
    mock('sudo', '''printf '%s\\n' "$*" >> "$TRACE"
[ "${CASE:-}" != denied ] || exit 1
case "$*" in *--ShowInstancesList*) [ "${CASE:-}" != amp-denied ] || exit 1;; esac
case "$*" in
  *apt-get\\ update*) [ "${CASE:-}" != metadata-failed ];;
  *install\\ --only-upgrade*) [ "${CASE:-}" != package-failed ];;
  *--UpgradeAll*) [ "${CASE:-}" != instance-failed ];;
  *--ShowInstancesList*)
    if [ "${CASE:-}" = inventory-failed ]; then
      if [ -f "$TRACE.inventory-seen" ]; then exit 1; fi
      : > "$TRACE.inventory-seen"
    fi;;
  *) exit 0;;
esac''')
    for case, expected in [('success',0),('denied',1),('amp-denied',1),('owner-mismatch',1),('backup-missing',1),('metadata-failed',1),('package-failed',1),('instance-failed',1),('inventory-failed',1),('macos',0),('absent',0)]:
        trace.write_text('')
        env = dict(os.environ, PATH=str(p), TRACE=str(trace), CASE=case,
                   AMP_UPDATE_BACKUP_CONFIRMED='0' if case=='backup-missing' else '1',
                   MOCK_OS='Darwin' if case=='macos' else 'Linux')
        if case=='absent':
            (p/'ampinstmgr').rename(p/'amp-hidden')
        result = subprocess.run(['/bin/bash',str(script)], env=env,stdin=subprocess.DEVNULL,capture_output=True,text=True)
        assert result.returncode==expected,(case,result.stdout,result.stderr)
        calls=trace.read_text()
        if case=='success':
            assert calls.splitlines() == [
                '-n true',
                '-n -u amp -i ampinstmgr --ShowInstancesList',
                '-n apt-get update',
                '-n apt-get install --only-upgrade ampinstmgr',
                '-n -u amp -i ampinstmgr --nocache --UpgradeAll true true',
                '-n -u amp -i ampinstmgr --ShowInstancesList',
            ], calls
        diagnostic = {
            'denied': 'authentication unavailable',
            'amp-denied': 'authentication unavailable',
            'owner-mismatch': 'unsupported package owner',
            'backup-missing': 'consistent configuration/world backup',
            'metadata-failed': 'metadata refresh failed',
            'package-failed': 'package update failed',
            'instance-failed': 'updates may be partial',
            'inventory-failed': 'running instance state is unverified',
        }.get(case)
        if diagnostic:
            assert diagnostic in result.stderr, (case, result.stderr)
        if case in ('denied','amp-denied','owner-mismatch','backup-missing','macos','absent'):
            assert 'apt-get' not in calls and '--UpgradeAll' not in calls
        if case in ('metadata-failed','package-failed'):
            assert '--UpgradeAll' not in calls
        print(f'PASS: {case}: exit {result.returncode}')
