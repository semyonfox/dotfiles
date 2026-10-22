#!/usr/bin/env python3
"""Isolated command fixtures, plus real SQLite backup/history checks. No network."""
import hashlib
import importlib.machinery
import importlib.util
import io
import json
import os
from pathlib import Path
import shutil
import sqlite3
import subprocess
import tarfile
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
HELPER = ROOT / 'server/bin/t3-update-state'
UPDATER = ROOT / 'server/bin/update-t3-nightly'
VERSION = '0.1.1-nightly.20261019.3373'


class UpdaterTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='t3-update-test-', dir=os.environ.get('TMPDIR'))
        self.root = Path(self.tmp.name)
        self.home = self.root / 'home'
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        self.base = self.home / '.t3'
        self.old = self.base / 'runtime/versions/0.0.46-nightly.20261005.2702'
        self.old.mkdir(parents=True)
        self.exe(self.old / 't3', "#!/bin/sh\necho 't3 v0.0.46-nightly.20261005.2702'\n")
        (self.base / 'runtime/headless-current').symlink_to(self.old)
        (self.home / '.local/bin').mkdir(parents=True)
        self.exe(self.home / '.local/bin/t3', '#!/bin/sh\necho old-npm-shim\n')
        (self.base / 'userdata').mkdir()
        (self.base / 'userdata/statev2.sqlite').write_bytes(b'fixture db')
        shutil.copy2(UPDATER, self.bin / 'update-t3-nightly')
        (self.bin / 'update-t3-nightly').chmod(0o755)
        # Helper mock for orchestration tests only. Real helper checked below.
        (self.bin / 't3-update-state').write_text('''import sys,os,shutil
from pathlib import Path
if sys.argv[1] == 'busy':
 candidate_active = (Path(os.environ['HOME']) / '.t3/runtime/headless-current').resolve().name != '0.0.46-nightly.20261005.2702'
 busy = os.environ.get('BUSY') or (os.environ.get('BUSY_ON_CANDIDATE') and candidate_active)
 print('{"busy":true}' if busy else '{"busy":false}')
 sys.exit(10 if busy else 0)
if sys.argv[1] == 'backup': shutil.copyfile(sys.argv[2],sys.argv[3])
if sys.argv[1] == 'inventory': print('{}')
''')
        self.archive = self.root / 'runtime.tar.gz'
        with tarfile.open(self.archive, 'w:gz') as tar:
            data = f'#!/bin/sh\necho "t3 v{VERSION}"\n'.encode()
            info = tarfile.TarInfo(f't3-{VERSION}-linux-x64/t3')
            info.mode = 0o755
            info.size = len(data)
            tar.addfile(info, io.BytesIO(data))
        digest = hashlib.sha256(self.archive.read_bytes()).hexdigest()
        release = {'tag_name': 'v' + VERSION, 'draft': False,
                   'published_at': '2026-10-19T18:47:42Z', 'assets': [{
                       'name': f't3-{VERSION}-linux-x64.tar.gz',
                       'browser_download_url': f'https://github.com/pingdotgg/t3code/releases/download/v{VERSION}/t3-{VERSION}-linux-x64.tar.gz',
                       'digest': 'sha256:' + digest}]}
        # Preview deliberately first; never choose it.
        preview = dict(release, tag_name='v0.1.1-preview.20261019.9999', published_at='2026-10-19T20:00:00Z')
        self.metadata = self.root / 'releases.json'
        self.metadata.write_text(json.dumps([preview, release]))
        self.exe(self.bin / 'curl', '''#!/usr/bin/env bash
if [[ ${NET_FAIL:-} ]]; then exit 22; fi
if [[ "$*" == *api.github.com* ]]; then /bin/cat "$FIXTURE/releases.json"; exit; fi
if [[ "$*" == *127.0.0.1* ]]; then exit 0; fi
if [[ ${DOWNLOAD_FAIL:-} ]]; then exit 22; fi
while (($#)); do if [[ $1 == -o ]]; then cp "$FIXTURE/runtime.tar.gz" "$2"; exit; fi; shift; done
exit 1
''')
        self.exe(self.bin / 'systemctl', '''#!/usr/bin/env bash
printf '%s\n' "$*" >> "$FIXTURE/systemctl.log"
case "$*" in
 *MainPID*) echo 123;;
 *'start '*)
   if [[ ${START_FAIL_ONCE:-} && ! -f $FIXTURE/first-start-failed ]]; then
     touch "$FIXTURE/first-start-failed"; exit 1
   fi
   [[ ! ${START_FAIL:-} ]] || exit 1;;
esac
''')
        self.exe(self.bin / 'readlink', '''#!/usr/bin/env bash
if [[ $* == *'/proc/456/exe'* ]]; then /usr/bin/readlink -f "$HOME/.t3/runtime/headless-current/t3"; else /usr/bin/readlink "$@"; fi
''')
        self.exe(self.bin / 'pgrep', '#!/bin/sh\necho 456\n')
        self.exe(self.bin / 'sleep', '#!/bin/sh\nexit 0\n')
        self.exe(self.bin / 'df', '#!/bin/sh\nprintf "Avail\\n999999999999\\n"\n')
        self.env = dict(os.environ, HOME=str(self.home), FIXTURE=str(self.root),
                        PATH=str(self.bin) + ':' + os.environ['PATH'])

    def tearDown(self):
        self.tmp.cleanup()

    @staticmethod
    def exe(path, text):
        path.write_text(text)
        path.chmod(0o755)

    def run_update(self, *args, **env):
        return subprocess.run(['bash', str(self.bin / 'update-t3-nightly'), *args],
                              env=dict(self.env, **env), capture_output=True, text=True)

    def test_check_is_read_only_and_uses_nightly(self):
        r = self.run_update('--check')
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn(VERSION, r.stdout)
        self.assertFalse((self.root / 'systemctl.log').exists())
        self.assertEqual((self.base / 'runtime/headless-current').resolve(), self.old)

    def test_busy_stages_but_never_stops(self):
        r = self.run_update(BUSY='1')
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertIn('DEFERRED', r.stdout)
        self.assertNotIn('stop ', (self.root / 'systemctl.log').read_text())
        self.assertEqual((self.base / 'runtime/headless-current').resolve(), self.old)

    def test_download_failure_leaves_runtime_unchanged(self):
        r = self.run_update(DOWNLOAD_FAIL='1')
        self.assertNotEqual(r.returncode, 0)
        self.assertEqual((self.base / 'runtime/headless-current').resolve(), self.old)
        self.assertFalse((self.root / 'systemctl.log').exists())

    def test_digest_mismatch_never_stops(self):
        self.archive.write_bytes(b'corrupt archive')
        r = self.run_update()
        self.assertNotEqual(r.returncode, 0)
        self.assertFalse((self.root / 'systemctl.log').exists())

    def test_success_and_already_current(self):
        r = self.run_update()
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertIn('UPDATED', r.stdout)
        self.assertEqual((self.home / '.local/bin/t3').resolve(), self.base / f'runtime/versions/{VERSION}/t3')
        before = (self.root / 'systemctl.log').read_text()
        r = self.run_update()
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertIn('CURRENT', r.stdout)
        self.assertEqual(before.count('stop '), (self.root / 'systemctl.log').read_text().count('stop '))

    def test_start_failure_rolls_back_pointer_and_preserves_failed_state(self):
        r = self.run_update(START_FAIL='1')
        self.assertNotEqual(r.returncode, 0)
        self.assertEqual((self.base / 'runtime/headless-current').resolve(), self.old)
        self.assertTrue(list((self.base / 'update-headless/backups').glob('*/failed-state/statev2.sqlite')))
        self.assertTrue((self.base / 'update-headless/transaction').exists())

    def test_candidate_start_failure_with_successful_old_runtime_recovery(self):
        r = self.run_update(START_FAIL_ONCE='1')
        self.assertNotEqual(r.returncode, 0)
        self.assertIn('ROLLED BACK', r.stdout)
        self.assertEqual((self.base / 'runtime/headless-current').resolve(), self.old)
        self.assertFalse((self.base / 'update-headless/transaction').exists())

    def test_metadata_failure_never_touches_service(self):
        r = self.run_update(NET_FAIL='1')
        self.assertNotEqual(r.returncode, 0)
        self.assertFalse((self.root / 'systemctl.log').exists())

    def test_new_candidate_work_prevents_disruptive_rollback(self):
        r = self.run_update(START_FAIL_ONCE='1', BUSY_ON_CANDIDATE='1')
        self.assertNotEqual(r.returncode, 0)
        self.assertIn('RECOVERY REQUIRED', r.stdout)
        self.assertTrue((self.base / 'update-headless/transaction').exists())
        self.assertEqual((self.base / 'runtime/headless-current').resolve().name, VERSION)
        self.assertEqual((self.root / 'systemctl.log').read_text().count('stop '), 1)

    def test_unsafe_verified_archive_rejected_even_with_python_optimization(self):
        with tarfile.open(self.archive, 'w:gz') as tar:
            data = b'escape'
            info = tarfile.TarInfo(f't3-{VERSION}-linux-x64/../escape')
            info.size = len(data)
            tar.addfile(info, io.BytesIO(data))
        metadata = json.loads(self.metadata.read_text())
        metadata[1]['assets'][0]['digest'] = 'sha256:' + hashlib.sha256(self.archive.read_bytes()).hexdigest()
        self.metadata.write_text(json.dumps(metadata))
        r = self.run_update(PYTHONOPTIMIZE='1')
        self.assertNotEqual(r.returncode, 0)
        self.assertIn('Unsafe archive path', r.stderr)
        self.assertFalse((self.root / 'systemctl.log').exists())

    def test_repeated_pending_reuses_verified_download(self):
        first = self.run_update(BUSY='1')
        self.assertEqual(first.returncode, 0, first.stdout + first.stderr)
        # Metadata still works, but no archive should be needed again.
        self.archive.unlink()
        second = self.run_update(BUSY='1')
        self.assertEqual(second.returncode, 0, second.stdout + second.stderr)
        self.assertIn('DEFERRED', second.stdout)

    def test_interrupted_transaction_blocks_future_mutation(self):
        state = self.base / 'update-headless'
        state.mkdir()
        (state / 'transaction').write_text('fixture interrupted transaction')
        r = self.run_update()
        self.assertNotEqual(r.returncode, 0)
        self.assertIn('RECOVERY REQUIRED', r.stderr)
        self.assertFalse((self.root / 'systemctl.log').exists())

    def test_pending_runtime_corruption_is_not_trusted(self):
        first = self.run_update(BUSY='1')
        self.assertEqual(first.returncode, 0, first.stdout + first.stderr)
        candidate = self.base / f'runtime/versions/{VERSION}/t3'
        candidate.write_text('corrupt staged executable')
        second = self.run_update(BUSY='1')
        self.assertNotEqual(second.returncode, 0)
        self.assertNotIn('stop ', (self.root / 'systemctl.log').read_text())
        self.assertEqual((self.base / 'runtime/headless-current').resolve(), self.old)

    def test_overlap_skips(self):
        import fcntl
        state = self.base / 'update-headless'
        state.mkdir()
        with (state / 'update.lock').open('w') as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            r = self.run_update()
            self.assertEqual(r.returncode, 0)
            self.assertIn('holds the lock', r.stdout)
            self.assertFalse((self.root / 'systemctl.log').exists())


class BusyGateTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        loader = importlib.machinery.SourceFileLoader('t3_state_test', str(HELPER))
        spec = importlib.util.spec_from_loader(loader.name, loader)
        assert spec is not None
        cls.helper = importlib.util.module_from_spec(spec)
        loader.exec_module(cls.helper)

    def setUp(self):
        self.db = sqlite3.connect(':memory:')
        self.db.executescript('''
          CREATE TABLE orchestration_v2_projection_runs(run_id TEXT, status TEXT);
          CREATE TABLE orchestration_v2_projection_nodes(node_id TEXT, run_id TEXT);
          CREATE TABLE orchestration_v2_projection_runtime_requests(node_id TEXT, status TEXT);
          CREATE TABLE orchestration_v2_projection_provider_threads(status TEXT);
          CREATE TABLE orchestration_v2_projection_provider_sessions(status TEXT);
          INSERT INTO orchestration_v2_projection_runs VALUES ('done','completed');
          INSERT INTO orchestration_v2_projection_nodes VALUES ('prompt','done');
          INSERT INTO orchestration_v2_projection_runtime_requests VALUES ('prompt','pending');
          INSERT INTO orchestration_v2_projection_provider_threads VALUES ('idle');
          INSERT INTO orchestration_v2_projection_provider_sessions VALUES ('ready');
        ''')
        self.home = '/fixture/.t3'
        self.runtime = self.home + '/runtime/versions/old/t3'
        self.ps = {}
        self.add(1, 0, '/usr/bin/flock', [])
        self.add(2, 1, self.runtime, [self.runtime, 'serve'])
        monitor = str(Path(self.runtime).parent / 'resource-monitor/linux-x64/t3-resource-monitor')
        self.add(3, 2, monitor, [monitor])
        self.add(4, 2, '/fixture/.local/share/claude/versions/known',
                 ['claude', '--input-format', 'stream-json', '--output-format', 'stream-json'])
        uv = '/fixture/.local/bin/uv'
        self.add(5, 4, uv, [uv, 'tool', 'uvx', '--python', '3.11', 'blender-mcp'])
        self.add(6, 5, '/fixture/.local/share/uv/python/known/bin/python3.11',
                 ['/fixture/.cache/uv/archive-v0/known/bin/python',
                  '/fixture/.cache/uv/archive-v0/known/bin/blender-mcp'])

    def tearDown(self):
        self.db.close()

    def add(self, pid, parent, exe, args):
        self.ps[pid] = dict(parent=parent, exe=exe, args=args)

    def test_idle_provider_blender_and_historical_prompt_do_not_block(self):
        self.assertEqual(self.helper.native_work(self.db), [])
        self.assertEqual(self.helper.process_work(self.ps, 1, self.home), [])

    def test_live_run_blocks_even_when_only_persistent_children_exist(self):
        self.db.execute("INSERT INTO orchestration_v2_projection_runs VALUES ('live','running')")
        self.assertTrue(self.helper.native_work(self.db))

    def test_orphan_request_unknown_status_and_active_provider_block(self):
        for sql in [
            "INSERT INTO orchestration_v2_projection_runtime_requests VALUES ('orphan','pending')",
            "INSERT INTO orchestration_v2_projection_runs VALUES ('unknown','future-status')",
            "INSERT INTO orchestration_v2_projection_provider_threads VALUES ('active')",
            "INSERT INTO orchestration_v2_projection_provider_sessions VALUES ('starting')",
        ]:
            with self.subTest(sql=sql):
                self.db.execute('SAVEPOINT fixture')
                self.db.execute(sql)
                self.assertTrue(self.helper.native_work(self.db))
                self.db.execute('ROLLBACK TO fixture')
                self.db.execute('RELEASE fixture')

    def test_outliving_tool_descendant_and_unreadable_process_block(self):
        for parent in (2, 4, 6):
            with self.subTest(parent=parent):
                self.add(7, parent, '/usr/bin/rsync', ['rsync'])
                self.assertTrue(self.helper.process_work(self.ps, 1, self.home))
                self.add(7, parent, '', [])
                self.assertTrue(self.helper.process_work(self.ps, 1, self.home))
                del self.ps[7]

    def test_blender_name_alone_is_not_an_allowlist(self):
        self.ps[6]['args'].append('--unrecognized-option')
        self.assertTrue(self.helper.process_work(self.ps, 1, self.home))

    def test_codex_appserver_and_code_mode_host(self):
        self.add(10, 2, '/fixture/.nvm/bin/node', ['node', '/fixture/.local/bin/codex', 'app-server'])
        exe = '/fixture/.nvm/lib/node_modules/@openai/codex/vendor/bin/codex'
        self.add(11, 10, exe, [exe, 'app-server'])
        host = str(Path(exe).with_name('codex-code-mode-host'))
        self.add(12, 11, host, [host])
        self.assertEqual(self.helper.process_work(self.ps, 1, self.home), [])
        self.add(13, 12, '/bin/bash', ['bash'])
        self.assertTrue(self.helper.process_work(self.ps, 1, self.home))

    def test_unknown_schema_fails_closed(self):
        self.db.execute('DROP TABLE orchestration_v2_projection_provider_threads')
        with self.assertRaises(sqlite3.OperationalError):
            self.helper.native_work(self.db)


class SQLiteTests(unittest.TestCase):
    def test_real_backup_and_id_continuity(self):
        with tempfile.TemporaryDirectory(dir=os.environ.get('TMPDIR')) as tmp:
            old, new = [Path(tmp) / n for n in ('old.sqlite', 'new.sqlite')]
            db = sqlite3.connect(old)
            for table in ('orchestration_events', 'orchestration_v2_events',
                          'orchestration_v2_projection_messages', 'projection_thread_messages'):
                db.execute(f'CREATE TABLE {table} (id INTEGER PRIMARY KEY, body TEXT)')
                db.execute(f'INSERT INTO {table} VALUES (1, "private fixture")')
            db.commit()
            subprocess.run(['python3', str(HELPER), 'backup', str(old), str(new)], check=True)
            subprocess.run(['python3', str(HELPER), 'compare', str(new), str(old)], check=True)
            changed = sqlite3.connect(new)
            changed.execute('INSERT INTO orchestration_events VALUES (2,"new")')
            changed.commit()
            subprocess.run(['python3', str(HELPER), 'compare', str(new), str(old)], check=True)
            changed.execute('DELETE FROM orchestration_events WHERE id=1')
            changed.commit()
            r = subprocess.run(['python3', str(HELPER), 'compare', str(new), str(old)],
                               capture_output=True, env=dict(os.environ, PYTHONOPTIMIZE='1'))
            self.assertNotEqual(r.returncode, 0)
            changed.close()
            db.close()


if __name__ == '__main__':
    unittest.main(verbosity=2)
