# T3 project DB dedupe and thread preservation

Use this when T3 Code shows missing/duplicated projects, especially when important workspaces such as Swim, Portfolio, OghmaNotes, Obsidian, CV, or `$HOME` appear fragmented or absent.

## Key finding pattern

T3 project visibility can fail even when the SQLite DB is structurally healthy. Distinguish these cases before fixing anything:

1. **Project never registered**: folder exists and may be mentioned in messages, but there is no `projection_projects` row and no `project.created` lifecycle event.
2. **Project exists but is marked deleted**: `projection_projects.deleted_at` is set.
3. **Project exists but history is hidden**: project row is active, but most `projection_threads.deleted_at` values are set.
4. **Duplicate project rows for one workspace**: multiple `projection_projects` rows share the same `workspace_root`; threads are split across UUIDs.
5. **Event log/projection disagreement**: `orchestration_events` may contain old `project.deleted` events even when the current projection row is active. Treat `projection_projects` as the UI-facing current projection, but preserve evidence before mutating.

## Non-destructive inspection

Run read-only first:

```bash
python3 - <<'PY'
import sqlite3
from pathlib import Path
DB=Path.home()/'.t3/userdata/state.sqlite'
con=sqlite3.connect(f'file:{DB}?mode=ro', uri=True)
cur=con.cursor()
print('integrity', cur.execute('PRAGMA integrity_check').fetchone()[0])
print('duplicate workspace roots')
for root,n in cur.execute("SELECT workspace_root,count(*) FROM projection_projects GROUP BY workspace_root HAVING count(*)>1 ORDER BY workspace_root"):
    print('\nROOT', root, 'count', n)
    for r in cur.execute('''
      SELECT p.project_id,p.title,p.created_at,p.updated_at,p.deleted_at,
             (SELECT count(*) FROM projection_threads t WHERE t.project_id=p.project_id) total_threads,
             (SELECT count(*) FROM projection_threads t WHERE t.project_id=p.project_id AND t.deleted_at IS NULL) visible_threads,
             (SELECT max(coalesce(t.latest_user_message_at,t.updated_at,t.created_at)) FROM projection_threads t WHERE t.project_id=p.project_id) last_thread_at
      FROM projection_projects p WHERE p.workspace_root=?
      ORDER BY (p.deleted_at IS NOT NULL), visible_threads DESC, total_threads DESC, created_at ASC
    ''', (root,)):
        print(' ', r)
con.close()
PY
```

For high-value projects, inspect exact roots and visible/deleted thread counts:

```sql
SELECT p.project_id,p.title,p.workspace_root,p.deleted_at,
       count(t.thread_id) total_threads,
       sum(CASE WHEN t.deleted_at IS NULL THEN 1 ELSE 0 END) visible_threads
FROM projection_projects p
LEFT JOIN projection_threads t ON t.project_id=p.project_id
WHERE p.workspace_root IN (...)
GROUP BY p.project_id;
```

## Safe merge procedure

Do **not** fix duplicates by running `t3 project add` for an already-present workspace; that creates more duplicates. Instead:

1. Stop the headless service.
2. Create a timestamped SQLite backup with the SQLite backup API, not raw copy while live.
3. Create an audit table to preserve removed duplicate project-row metadata.
4. Pick a canonical project per `workspace_root`:
   - prefer active row (`deleted_at IS NULL`),
   - then highest visible thread count,
   - then highest total thread count,
   - then oldest `created_at`.
5. Move every duplicate row's `projection_threads.project_id` to the canonical UUID.
6. Insert each removed row into `t3_project_merge_audit` with old UUID/title/timestamps/thread counts.
7. Delete only the duplicate `projection_projects` rows after their threads have moved.
8. Update canonical `created_at` to oldest creation, `updated_at` to max of project/thread timestamps, and keep it active if any duplicate was active.
9. Run `PRAGMA integrity_check`, confirm `duplicate_workspace_groups = 0`, restart T3, and hit the health endpoint.

Example backup/stop:

```bash
systemctl --user stop t3-code-headless.service
stamp=$(date +%Y%m%d-%H%M%S)
backup="$HOME/.t3/userdata/state.sqlite.backup-before-project-merge-$stamp"
python3 - <<PY
import sqlite3
from pathlib import Path
src=Path.home()/'.t3/userdata/state.sqlite'
dst=Path('$backup')
s=sqlite3.connect(f'file:{src}?mode=ro', uri=True)
d=sqlite3.connect(dst)
s.backup(d)
d.close(); s.close()
print(dst, dst.stat().st_size)
PY
```

## Important pitfall

Merging duplicate projects only consolidates ownership; it does **not** undelete threads. A result like `swim: 268 threads, 1 visible` means the duplicate UUIDs were merged successfully, but most rows in `projection_threads` still have `deleted_at` set. Make a separate, deliberate repair pass if the user wants hidden/deleted threads visible again.

## Verification targets

After merge:

```sql
SELECT count(*) FROM (
  SELECT workspace_root FROM projection_projects GROUP BY workspace_root HAVING count(*) > 1
);
PRAGMA integrity_check;
SELECT p.project_id,p.title,p.deleted_at,count(t.thread_id),sum(CASE WHEN t.deleted_at IS NULL THEN 1 ELSE 0 END)
FROM projection_projects p
LEFT JOIN projection_threads t ON t.project_id=p.project_id
WHERE p.workspace_root=?
GROUP BY p.project_id;
```

Then:

```bash
systemctl --user start t3-code-headless.service
systemctl --user show t3-code-headless.service -p ActiveState -p SubState -p MainPID -p NRestarts --no-pager
curl -fsS --max-time 10 http://127.0.0.1:3773/.well-known/t3/environment
```
