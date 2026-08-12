# T3 project registry vs filesystem inventory

Use this when Semyon says projects are missing from T3 Code, asks whether projects are in the DB, or wants GitHub links reconstructed from local folders.

## Core lesson

T3's SQLite DB is a project/thread registry, not the canonical source of truth for Semyon's projects. A folder under `~/code` or a GitHub remote does **not** imply a `projection_projects` row. Many repos may only appear as text mentions in messages/tool output under broad projects such as `/home/semyon`, `/home/semyon/code/personal`, `portfolio`, `obsidian`, or `oghmanotes`.

Distinguish these states:

1. **Filesystem-only / not first-class T3 project**
   - Folder exists on disk.
   - `projection_projects` has no exact/LIKE match for title/root.
   - `orchestration_events` has no `project.created` for the name/path.
   - The name may still appear in `thread.message-sent` or `thread.activity-appended` payloads under another project.
   - Fix: add with supported CLI, e.g. `~/.local/bin/t3 project add /path --title name`.

2. **Deleted T3 project**
   - `projection_projects.deleted_at IS NOT NULL`.
   - Usually has `project.created` and `project.deleted` lifecycle events.
   - Threads may also be deleted/hidden.
   - Fix: safest is re-add through CLI after backup rather than hand-clearing `deleted_at`.

3. **Active project with pruned/deleted thread history**
   - `projection_projects.deleted_at IS NULL`.
   - Many rows in `projection_threads`, but few with `deleted_at IS NULL`.
   - The project exists; only visible thread history is missing/pruned.

## Read-only DB probes

Use read-only SQLite URI and avoid mutating until a backup exists:

```bash
python3 - <<'PY'
import sqlite3, json
from pathlib import Path
DB = Path.home()/'.t3/userdata/state.sqlite'
con = sqlite3.connect(f'file:{DB}?mode=ro', uri=True)
cur = con.cursor()
print('quick_check', cur.execute('PRAGMA quick_check').fetchone()[0])
for table in ['projection_projects','projection_threads','projection_thread_messages','projection_thread_activities','orchestration_events']:
    print(table, cur.execute(f'SELECT count(*) FROM {table}').fetchone()[0])
con.close()
PY
```

Check a suspected project name:

```bash
name='ScrimBrain'
python3 - <<PY
import sqlite3, json
from pathlib import Path
DB=Path.home()/'.t3/userdata/state.sqlite'
name='$name'
con=sqlite3.connect(f'file:{DB}?mode=ro', uri=True)
cur=con.cursor()
print('projection_projects')
for r in cur.execute("""
SELECT project_id,title,workspace_root,created_at,updated_at,deleted_at
FROM projection_projects
WHERE lower(title) LIKE lower(?) OR lower(workspace_root) LIKE lower(?)
ORDER BY created_at
""", (f'%{name}%', f'%{name}%')):
    print(r)
print('project lifecycle events')
for seq,et,occ,sid,payload in cur.execute("""
SELECT sequence,event_type,occurred_at,stream_id,payload_json
FROM orchestration_events
WHERE event_type LIKE 'project.%' AND payload_json LIKE ?
ORDER BY sequence
""", (f'%{name}%',)):
    p=json.loads(payload)
    print(seq, et, occ, sid, {k:p.get(k) for k in ['projectId','title','workspaceRoot','deletedAt','updatedAt'] if k in p})
print('thread/message mentions mapped to actual projects')
for r in cur.execute("""
SELECT DISTINCT t.thread_id,t.title,t.worktree_path,t.deleted_at,p.title,p.workspace_root,p.deleted_at
FROM projection_threads t
JOIN projection_projects p ON p.project_id=t.project_id
LEFT JOIN projection_thread_messages m ON m.thread_id=t.thread_id
WHERE t.title LIKE ? OR t.worktree_path LIKE ? OR m.text LIKE ?
LIMIT 20
""", (f'%{name}%', f'%{name}%', f'%{name}%')):
    print(r)
con.close()
PY
```

## Filesystem + GitHub link manifest pattern

To reconstruct what should be visible in T3, scan real project roots, compare against `projection_projects.workspace_root`, and read Git remotes:

```bash
python3 - <<'PY'
import sqlite3, subprocess
from pathlib import Path
DB=Path.home()/'.t3/userdata/state.sqlite'
bases=[Path.home()/'code/personal', Path.home()/'code/university', Path.home()/'compsoc']
con=sqlite3.connect(f'file:{DB}?mode=ro', uri=True)
cur=con.cursor()
projects={}
for row in cur.execute('SELECT project_id,title,workspace_root,deleted_at FROM projection_projects'):
    projects.setdefault(row[2],[]).append(row)

def remote(p):
    r=subprocess.run(['git','-C',str(p),'remote','-v'], text=True, capture_output=True, timeout=5)
    if r.returncode: return ''
    for line in r.stdout.splitlines():
        parts=line.split()
        if len(parts)>=3 and parts[0]=='origin' and parts[2]=='(fetch)': return parts[1]
    return ''

for base in bases:
    if not base.exists(): continue
    for p in sorted([x for x in base.iterdir() if x.is_dir() and not x.name.startswith('.')], key=lambda x:x.name.lower()):
        dbs=projects.get(str(p), [])
        status='NOT_IN_DB'
        if dbs:
            status='ACTIVE_DB' if any(d[3] is None for d in dbs) else 'DELETED_DB'
        git=(p/'.git').exists()
        print(f'{status:10} git={git!s:5} {p} {remote(p) if git else ""}')
con.close()
PY
```

## Safe recovery sequence

1. Inventory first; do not infer deletion from absence in the UI.
2. Run SQLite health checks read-only.
3. For each missing folder, classify as `NOT_IN_DB`, `DELETED_DB`, or `ACTIVE_DB with deleted threads`.
4. Preserve the DB with SQLite backup API before mutation.
5. Re-add missing/deleted real repos through the supported CLI:

```bash
~/.local/bin/t3 project add '/home/semyon/code/personal/ScrimBrain' --title 'ScrimBrain'
```

Avoid direct DB edits unless the CLI cannot represent the intended state and Semyon explicitly approves a surgical repair.
