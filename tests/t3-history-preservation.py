#!/usr/bin/env python3
"""Real SQLite compaction-aware preservation fixtures, no production state."""
import importlib.machinery,importlib.util,json,os,sqlite3,tempfile,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
loader=importlib.machinery.SourceFileLoader('guard',str(ROOT/'server/bin/t3-update-state'))
spec=importlib.util.spec_from_loader(loader.name,loader);guard=importlib.util.module_from_spec(spec);loader.exec_module(guard)
class PreservationTests(unittest.TestCase):
 def setUp(self):
  self.tmp=tempfile.TemporaryDirectory(dir=os.environ.get('TMPDIR'));self.old=Path(self.tmp.name)/'old.sqlite';self.new=Path(self.tmp.name)/'new.sqlite'
  c=sqlite3.connect(self.old)
  c.executescript('''CREATE TABLE orchestration_events(sequence INTEGER PRIMARY KEY,event_id TEXT,aggregate_kind TEXT,stream_id TEXT,event_type TEXT,occurred_at TEXT,payload_json TEXT,application_event_version INTEGER);
  CREATE TABLE orchestration_v2_events(id INTEGER PRIMARY KEY,body TEXT);
  CREATE TABLE orchestration_v2_projection_messages(message_id TEXT PRIMARY KEY,payload_json TEXT);
  CREATE TABLE projection_thread_messages(message_id TEXT PRIMARY KEY,text TEXT);
  CREATE TABLE orchestration_v2_projection_turn_items(turn_item_id TEXT PRIMARY KEY,payload_json TEXT);
  CREATE TABLE orchestration_v2_projection_checkpoints(checkpoint_id TEXT PRIMARY KEY,payload_json TEXT);
  CREATE TABLE orchestration_v2_legacy_imports(thread_id TEXT PRIMARY KEY,transcript_imported_at TEXT);
  INSERT INTO orchestration_v2_projection_messages VALUES('m','{"id":"m","text":"final answer"}');
  INSERT INTO orchestration_v2_projection_turn_items VALUES('tool','{"output":"private fixture"}');
  INSERT INTO orchestration_v2_projection_checkpoints VALUES('c','{"diff":"private diff"}');''')
  self.event(c,1,'message.updated',{'id':'m','text':'first'});self.event(c,2,'message.updated',{'id':'m','text':'middle'});self.event(c,3,'message.updated',{'id':'m','text':'final answer'})
  c.commit();d=sqlite3.connect(self.new);c.backup(d);c.close();d.close()
 def tearDown(self):self.tmp.cleanup()
 def event(self,c,seq,typ,payload,version=2):c.execute('insert into orchestration_events values(?,?,?,?,?,?,?,?)',(seq,'event:'+str(seq),'thread','t',typ,'2026-10-19T21:00:00Z',json.dumps(payload),version))
 def alter(self,sql,*args):
  c=sqlite3.connect(self.new);c.execute(sql,args);c.commit();c.close()
 def compare(self):return guard.compare_history(self.new,self.old)
 def test_middle_revision_compaction_preserves_full_history(self):
  self.alter('delete from orchestration_events where sequence=2');self.compare()
 def test_first_and_latest_anchor_removal_fail(self):
  for seq in (1,3):
   with self.subTest(seq=seq):
    c=sqlite3.connect(self.new);c.execute('delete from orchestration_events where sequence=?',(seq,));c.commit();c.close()
    with self.assertRaises(RuntimeError):self.compare()
    c=sqlite3.connect(self.old);d=sqlite3.connect(self.new);c.backup(d);c.close();d.close()
 def test_tool_checkpoint_and_message_payload_mutations_fail(self):
  for table,col,key in [('orchestration_v2_projection_turn_items','turn_item_id','tool'),('orchestration_v2_projection_checkpoints','checkpoint_id','c'),('orchestration_v2_projection_messages','message_id','m')]:
   with self.subTest(table=table):
    self.alter('update '+table+' set payload_json=? where '+col+'=?','{}',key)
    with self.assertRaises(RuntimeError):self.compare()
    c=sqlite3.connect(self.old);d=sqlite3.connect(self.new);c.backup(d);c.close();d.close()
 def test_unknown_unique_event_removal_fails(self):
  c=sqlite3.connect(self.old);self.event(c,4,'tool.unique-result',{'id':'x'});c.commit();c.close()
  with self.assertRaises(RuntimeError):self.compare()
 def test_thread_and_read_supersession(self):
  for p in (self.old,self.new):
   c=sqlite3.connect(p)
   self.event(c,4,'thread.metadata-updated',{'id':'t','title':'older'});self.event(c,5,'thread.visited',{'id':'t','title':'older'});self.event(c,6,'thread.metadata-updated',{'id':'t','title':'latest'});c.commit();c.close()
  self.alter('delete from orchestration_events where sequence in (4,5)');self.compare()
 def test_read_event_does_not_supersede_activity(self):
  for p in (self.old,self.new):
   c=sqlite3.connect(p);self.event(c,4,'thread.metadata-updated',{'id':'t'});self.event(c,5,'thread.visited',{'id':'t'});c.commit();c.close()
  self.alter('delete from orchestration_events where sequence=4')
  with self.assertRaises(RuntimeError):self.compare()
 def test_retained_event_payload_mutation_fails(self):
  self.alter('update orchestration_events set payload_json=? where sequence=2','{"id":"m","text":"corrupted"}')
  with self.assertRaises(RuntimeError):self.compare()
 def test_imported_legacy_compaction_requires_ready_import_and_messages(self):
  for p in (self.old,self.new):
   c=sqlite3.connect(p);self.event(c,4,'thread.activity-appended',{'tool':'fixture'},1);c.execute("insert into orchestration_v2_legacy_imports values('t','2026-10-19')");c.commit();c.close()
  self.alter('delete from orchestration_events where sequence=4');self.compare()
  self.alter('update orchestration_v2_legacy_imports set transcript_imported_at=NULL')
  with self.assertRaises(RuntimeError):self.compare()
 def test_canonical_startup_node_settlement_and_arbitrary_change_rejection(self):
  oldpayload={'id':'node','threadId':'t','status':'running','completedAt':None,'runId':'original'}
  newpayload=dict(oldpayload,status='cancelled',completedAt='2026-10-19T21:00:00Z')
  for p in (self.old,self.new):
   c=sqlite3.connect(p);c.execute('CREATE TABLE orchestration_v2_projection_nodes(node_id TEXT PRIMARY KEY,status TEXT,completed_at TEXT,payload_json TEXT)');c.execute('insert into orchestration_v2_projection_nodes values(?,?,?,?)',('node','running',None,json.dumps(oldpayload)));c.commit();c.close()
  c=sqlite3.connect(self.new);self.event(c,4,'node.updated',newpayload);c.execute('update orchestration_v2_projection_nodes set status=?,completed_at=?,payload_json=?',('cancelled',newpayload['completedAt'],json.dumps(newpayload)));c.commit();c.close()
  self.compare()
  self.alter('update orchestration_v2_projection_nodes set completed_at=?','tampered scalar timestamp')
  with self.assertRaises(RuntimeError):self.compare()
  self.alter('update orchestration_v2_projection_nodes set completed_at=?',newpayload['completedAt'])
  newpayload['runId']='unjustified replacement'
  c=sqlite3.connect(self.new);c.execute('update orchestration_events set payload_json=? where sequence=4',(json.dumps(newpayload),));c.execute('update orchestration_v2_projection_nodes set payload_json=?',(json.dumps(newpayload),));c.commit();c.close()
  with self.assertRaises(RuntimeError):self.compare()
 def test_missing_critical_history_schema_fails(self):
  self.alter('drop table orchestration_v2_projection_messages')
  with self.assertRaises(RuntimeError):self.compare()
if __name__=='__main__':unittest.main(verbosity=2)
