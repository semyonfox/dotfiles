# T3 project registry and thread visibility triage

Use this when Semyon says projects are missing from T3 Code, especially important projects like Swim, Portfolio, or OghmaNotes.

## Core lesson

Do not assume "missing from the UI" means the project is absent from SQLite. T3 can have several different states that look the same to the user:

1. Folder exists on disk but was never registered as a T3 project.
2. Project row exists in `projection_projects` and is active, but nearly all threads are marked deleted.
3. Duplicate project rows exist for the same `workspace_root`, with some active and some deleted.
4. Event log and projection table disagree: `orchestration_events` may contain `project.deleted` while `projection_projects.deleted_at` is currently `NULL`.
5. The project is present only as a text mention inside a broader project/thread, not as a first-class project row.

For canonical projects (`swim`, `portfolio`, `oghmanotes`), do **not** blindly run `t3 project add`: they may already exist and re-adding creates more duplicates. First determine whether they are absent, deleted, duplicated, or merely thread-pruned.

## Read-only DB triage

Live DB path is normally:

```bash
/home/semyon/.t3/userdata/state.sqlite
```

Use Python/sqlite read-only rather than hand-editing:

```bash
python3 - <<'PY'
import sqlite3, json
from pathlib import Path
DB = Path.home()/'.t3/userdata/state.sqlite'
roots = [
    '/home/semyon/code/personal/swim',
    '/home/semyon/code/personal/portfolio',
    '/home/semyon/code/university/ct216-software-eng/oghmanotes',
]
con = sqlite3.connect(f'file:{DB}?mode=ro', uri=True)
cur = con.cursor()
print('quick_check', cur.execute('PRAGMA quick_check').fetchone()[0])
for root in roots:
    print('\n###', root)
    for p in cur.execute('''
      SELECT project_id,title,workspace_root,created_at,updated_at,deleted_at,default_model_selection_json
      FROM projection_projects
      WHERE workspace_root=?
      ORDER BY created_at
    ''', (root,)):
        pid,title,wroot,created,updated,deleted,model = p
        print('PROJECT', dict(project_id=pid,title=title,workspace_root=wroot,created_at=created,updated_at=updated,deleted_at=deleted,model=model))
        print('thread_stats', cur.execute('''
          SELECT count(*),
                 sum(CASE WHEN deleted_at IS NULL THEN 1 ELSE 0 END),
                 sum(CASE WHEN deleted_at IS NOT NULL THEN 1 ELSE 0 END),
                 sum(CASE WHEN archived_at IS NOT NULL AND deleted_at IS NULL THEN 1 ELSE 0 END),
                 max(coalesce(latest_user_message_at,updated_at,created_at))
          FROM projection_threads WHERE project_id=?
        ''', (pid,)).fetchone())
        print('latest visible')
        for t in cur.execute('''
          SELECT thread_id,title,created_at,updated_at,deleted_at,archived_at,latest_user_message_at,worktree_path
          FROM projection_threads
          WHERE project_id=? AND deleted_at IS NULL
          ORDER BY coalesce(latest_user_message_at,updated_at,created_at) DESC LIMIT 12
        ''', (pid,)):
            print(' ', t)
        print('latest deleted')
        for t in cur.execute('''
          SELECT thread_id,title,created_at,updated_at,deleted_at,archived_at,latest_user_message_at,worktree_path
          FROM projection_threads
          WHERE project_id=? AND deleted_at IS NOT NULL
          ORDER BY deleted_at DESC LIMIT 8
        ''', (pid,)):
            print(' ', t)
        print('project lifecycle events')
        for seq,et,occ,payload in cur.execute('''
          SELECT sequence,event_type,occurred_at,payload_json
          FROM orchestration_events
          WHERE (stream_id=? OR payload_json LIKE ?) AND event_type LIKE 'project.%'
          ORDER BY sequence
        ''', (pid, f'%{pid}%')):
            try: pl=json.loads(payload)
            except Exception: pl={}
            print(' ', seq, et, occ, {k:pl.get(k) for k in ['projectId','title','workspaceRoot','deletedAt','updatedAt'] if k in pl})
con.close()
PY
```

Interpretation:

- `projection_projects.deleted_at IS NULL` means the current projection considers the project active.
- A project can be active but unusable-looking if `projection_threads` has very few non-deleted threads.
- Duplicate active rows for the same `workspace_root` should be treated as a dedupe/repair task, not as missing data.
- `project.deleted` events in `orchestration_events` alongside active projection rows are a red flag that event history and projection state disagree. Report this plainly before mutating.

## Check absent vs mentioned-only

For a folder suspected to be missing, distinguish first-class project rows from mere mentions in messages/tool output:

```sql
SELECT project_id,title,workspace_root,created_at,updated_at,deleted_at
FROM projection_projects
WHERE lower(title) LIKE lower('%NAME%') OR lower(workspace_root) LIKE lower('%NAME%');

SELECT sequence,event_type,occurred_at,stream_id,payload_json
FROM orchestration_events
WHERE event_type LIKE 'project.%' AND payload_json LIKE '%NAME%'
ORDER BY sequence;

SELECT DISTINCT t.thread_id,t.title,t.worktree_path,t.deleted_at,p.title,p.workspace_root,p.deleted_at
FROM projection_threads t
JOIN projection_projects p ON p.project_id=t.project_id
LEFT JOIN projection_thread_messages m ON m.thread_id=t.thread_id
WHERE t.title LIKE '%NAME%' OR t.worktree_path LIKE '%NAME%' OR m.text LIKE '%NAME%'
LIMIT 10;
```

If project lifecycle events are zero but thread/message mentions exist, the folder was probably discussed inside another umbrella project (`/home/semyon`, `portfolio`, `obsidian`, etc.) and was never registered as its own T3 project.

## Repair discipline

Before any repair:

1. Stop and explain which category applies: absent, deleted, duplicate, active-but-thread-pruned, or projection/event mismatch.
2. Make a timestamped SQLite backup using the SQLite backup API, not a blind copy while the service is writing.
3. Prefer T3 CLI (`t3 project add`) only for folders that truly have no project row/lifecycle event.
4. Do **not** use `t3 project add` for canonical existing projects like Swim/Portfolio/OghmaNotes; repair/dedupe/undelete instead.
5. After repair, restart the T3 service and verify both SQLite counts and the UI-facing app state.

## Known examples from July 2026 triage

At one point:

- `swim` had an active project row, plus a deleted duplicate; only 1 visible thread out of 268 combined.
- `portfolio` had two active rows for the same workspace root; only 6 visible threads out of 32 combined.
- `oghmanotes` had an active project row; only 7 visible threads out of 127.
- Many other folders existed on disk and had Git remotes but had no `projection_projects` row; they were only mentioned in broader project threads.

These examples are illustrative, not permanent facts. Re-run read-only queries every time.
