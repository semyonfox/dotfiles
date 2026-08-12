# T3 project index missing-project triage

Use this when T3 Code appears to be missing projects from the project picker/sidebar, especially on the headless server backend.

## Read-only diagnosis first

Do not assume the DB is corrupt or manually edit `deleted_at` first. Check the live SQLite projection read-only and compare it with the filesystem.

```bash
python3 - <<'PY'
import sqlite3
from pathlib import Path
DB = Path.home() / '.t3/userdata/state.sqlite'
con = sqlite3.connect(f'file:{DB}?mode=ro', uri=True, timeout=30)
cur = con.cursor()
print('quick_check', cur.execute('PRAGMA quick_check').fetchone()[0])

print('\n== project visibility summary ==')
q = '''
SELECT p.title,p.workspace_root,p.project_id,p.created_at,p.updated_at,p.deleted_at,
       COUNT(t.thread_id) total_threads,
       SUM(CASE WHEN t.deleted_at IS NULL THEN 1 ELSE 0 END) visible_threads,
       SUM(CASE WHEN t.deleted_at IS NOT NULL THEN 1 ELSE 0 END) deleted_threads,
       SUM(CASE WHEN t.archived_at IS NOT NULL AND t.deleted_at IS NULL THEN 1 ELSE 0 END) archived_visible_threads,
       MAX(COALESCE(t.latest_user_message_at,t.updated_at,t.created_at)) last_thread_at
FROM projection_projects p
LEFT JOIN projection_threads t ON t.project_id=p.project_id
GROUP BY p.project_id
ORDER BY (p.deleted_at IS NOT NULL), lower(p.title), p.workspace_root
'''
for r in cur.execute(q):
    title, root, pid, created, updated, deleted, total, visible, deleted_threads, arch, last = r
    exists = Path(root).exists()
    status = 'DELETED' if deleted else 'ACTIVE'
    print(f'{status:7} fs={str(exists):5} threads={total or 0:3}/{visible or 0:3} '
          f'delthr={deleted_threads or 0:3} arch={arch or 0:3} title={title!r} root={root} deleted={deleted}')

print('\n== relationship checks ==')
checks = {
  'threads_missing_project': "SELECT count(*) FROM projection_threads t LEFT JOIN projection_projects p ON p.project_id=t.project_id WHERE p.project_id IS NULL",
  'messages_missing_thread': "SELECT count(*) FROM projection_thread_messages m LEFT JOIN projection_threads t ON t.thread_id=m.thread_id WHERE t.thread_id IS NULL",
  'activities_missing_thread': "SELECT count(*) FROM projection_thread_activities a LEFT JOIN projection_threads t ON t.thread_id=a.thread_id WHERE t.thread_id IS NULL",
  'sessions_missing_thread': "SELECT count(*) FROM projection_thread_sessions s LEFT JOIN projection_threads t ON t.thread_id=s.thread_id WHERE t.thread_id IS NULL",
  'turns_missing_thread': "SELECT count(*) FROM projection_turns u LEFT JOIN projection_threads t ON t.thread_id=u.thread_id WHERE t.thread_id IS NULL",
}
for name, sql in checks.items():
    print(name, cur.execute(sql).fetchone()[0])
con.close()
PY
```

Healthy-but-missing-project pattern:

- `PRAGMA quick_check` returns `ok`.
- Relationship checks are all `0`.
- Missing folders are either absent from `projection_projects`, or present with `deleted_at` set.
- Many projects may have zero visible threads because all their threads are soft-deleted; this does not mean the project row is corrupt.

## Compare filesystem roots with the T3 project table

```bash
python3 - <<'PY'
import sqlite3
from pathlib import Path
DB = Path.home() / '.t3/userdata/state.sqlite'
con = sqlite3.connect(f'file:{DB}?mode=ro', uri=True)
cur = con.cursor()
roots = set(r[0] for r in cur.execute('SELECT workspace_root FROM projection_projects'))
active = set(r[0] for r in cur.execute('SELECT workspace_root FROM projection_projects WHERE deleted_at IS NULL'))
for base in [Path.home()/'code/personal', Path.home()/'code/university', Path.home()/'compsoc']:
    print('BASE', base)
    if not base.exists():
        continue
    for p in sorted([x for x in base.iterdir() if x.is_dir() and not x.name.startswith('.')], key=lambda x: x.name.lower()):
        marker = 'ACTIVE_DB' if str(p) in active else ('DELETED_DB' if str(p) in roots else 'NOT_IN_DB')
        print(f'{marker:10} git={(p/'.git').exists()!s:5} {p}')
con.close()
PY
```

## Safe recovery path

Prefer the supported CLI over direct SQLite writes:

```bash
~/.local/bin/t3 project add /home/semyon/code/personal/ScrimBrain --title ScrimBrain
```

For folders marked `DELETED_DB` but intended to be visible again, re-add with the CLI rather than manually clearing `deleted_at` unless you have already backed up and intentionally chosen DB surgery.

Before bulk recovery, make a SQLite backup/preservation copy. Do not mutate the DB while the service is running unless the CLI command is doing the mutation.

## Related bloat signal

A missing-project report can coexist with DB bloat. Count activity kinds and event types so you do not confuse project-index issues with event-log size:

```sql
SELECT kind,count(*) FROM projection_thread_activities GROUP BY kind ORDER BY count(*) DESC LIMIT 20;
SELECT event_type,count(*) FROM orchestration_events GROUP BY event_type ORDER BY count(*) DESC LIMIT 20;
```

Large `tool.updated`, `thread.message-sent`, or `thread.activity-appended` counts explain multi-GB DB size, but they are not by themselves evidence that projects were lost.
