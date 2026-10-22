#!/usr/bin/env python3
"""Storage/maintenance regression fixtures. Never touches live services/data."""
import importlib.util
from pathlib import Path
import os
import unittest
spec=importlib.util.spec_from_file_location('t3_base',Path(__file__).with_name('update-t3-nightly.py'))
assert spec is not None and spec.loader is not None
base=importlib.util.module_from_spec(spec);spec.loader.exec_module(base)
class StorageTests(unittest.TestCase):
    tearDown=base.UpdaterTests.tearDown
    exe=staticmethod(base.UpdaterTests.exe)
    run_update=base.UpdaterTests.run_update
    def setUp(self):
        base.UpdaterTests.setUp(self)
        self.backup_root=self.root/'private external rollback'
        self.backup_root.mkdir(mode=0o700)
        cfg=self.home/'.config/t3-nightly-update/backup-root'
        cfg.parent.mkdir(parents=True);cfg.write_text(str(self.backup_root)+'\n')
        helper=self.bin/'t3-update-state'
        text=helper.read_text().replace("if sys.argv[1] == 'backup': shutil.copyfile(sys.argv[2],sys.argv[3])", """if sys.argv[1] == 'backup':
 with open(Path(os.environ['FIXTURE'])/'backup-calls','a') as log: log.write(sys.argv[3]+'\\n')
 if os.environ.get('BACKUP_FAIL'): sys.exit(1)
 shutil.copyfile(sys.argv[2],sys.argv[3])""")
        helper.write_text(text)
    def test_explicit_maintenance_quiesces_busy_work_without_weakening_default(self):
        ctl=self.bin/'systemctl'
        text=ctl.read_text().replace(" *MainPID*) echo 123;;", """ *MainPID*) if [[ -f $FIXTURE/stopped ]]; then echo 0; else echo 123; fi;;
 *SubState*) echo dead;;
 *'stop '*) touch "$FIXTURE/stopped";;""").replace(" *'start '*)", " *'start '*) rm -f \"$FIXTURE/stopped\";")
        ctl.write_text(text)
        r=self.run_update('--maintenance-stop',BUSY='1')
        self.assertEqual(r.returncode,0,r.stdout+r.stderr)
        self.assertIn('UPDATED',r.stdout)
        self.assertTrue((self.base/'update-headless/maintenance-busy.json').exists())
        self.assertEqual(len((self.root/'backup-calls').read_text().splitlines()),1)
    def test_maintenance_retains_recovery_interlock(self):
        (self.base/'update-headless').mkdir(parents=True)
        (self.base/'update-headless/transaction').write_text('unresolved fixture')
        r=self.run_update('--maintenance-stop',BUSY='1')
        self.assertNotEqual(r.returncode,0)
        self.assertIn('RECOVERY REQUIRED',r.stderr)
        self.assertFalse((self.root/'backup-calls').exists())
    def test_maintenance_requires_confirmed_stopped_service(self):
        r=self.run_update('--maintenance-stop',BUSY='1')
        self.assertNotEqual(r.returncode,0)
        self.assertEqual((self.base/'runtime/headless-current').resolve(),self.old)
        self.assertFalse((self.root/'backup-calls').exists())
    def test_configured_private_backup_root_and_single_stopped_snapshot(self):
        r=self.run_update()
        self.assertEqual(r.returncode,0,r.stdout+r.stderr)
        copies=(self.root/'backup-calls').read_text().splitlines()
        self.assertEqual(len(copies),1,'Do not duplicate online+stopped full snapshots')
        self.assertTrue(Path(copies[0]).is_relative_to(self.backup_root))
        self.assertTrue(list(self.backup_root.glob('*/statev2.sqlite.gz')))
    def test_missing_configured_storage_never_stops(self):
        self.backup_root.rmdir()
        r=self.run_update()
        self.assertNotEqual(r.returncode,0)
        log=self.root/'systemctl.log'
        self.assertNotIn('stop ',log.read_text() if log.exists() else '')
    def test_failed_preswitch_snapshot_restarts_original_without_data_restore(self):
        r=self.run_update(BACKUP_FAIL='1')
        self.assertNotEqual(r.returncode,0)
        self.assertEqual((self.base/'runtime/headless-current').resolve(),self.old)
        self.assertEqual((self.base/'userdata/statev2.sqlite').read_bytes(),b'fixture db')
        log=(self.root/'systemctl.log').read_text()
        self.assertIn('stop ',log);self.assertIn('start ',log)
        self.assertFalse((self.base/'update-headless/transaction').exists())
        self.assertFalse(list(self.backup_root.glob('*/failed-state')))
if __name__=='__main__':unittest.main()
