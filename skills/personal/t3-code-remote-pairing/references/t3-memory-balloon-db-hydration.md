# T3 memory balloon: DB/event hydration triage

Use when the T3 headless backend stays reachable only after raising `NODE_OPTIONS=--max-old-space-size`, crashes with V8 heap OOM, or feels slow/fat while the public tunnel still proxies.

## Root-cause pattern seen on Semyon's server

The failure was not just "Node needs more RAM". The installed server was constructing very large JS object graphs from SQLite state:

- `ProjectionSnapshotQuery.getSnapshot()` eagerly reads all projects, threads, messages, proposed plans, activities, sessions, checkpoints, latest turns, and projection state.
- `listThreadActivityRows(undefined)` has no pagination/limit and selects the full `projection_thread_activities` table.
- `getThreadDetailById(threadId)` also eagerly loads all messages/plans/activities/checkpoints for that one thread.
- Raw JSON rows expand significantly when decoded/schema-validated into JS arrays/objects/strings, so hundreds of MB of payload JSON can become multiple GB of RSS/heap.

A contributing bug was the installed package still persisting high-frequency provider `item.updated` events as `tool.updated` activities. Local source had the intended fix (`case "item.updated": return [];`) but the running npm-installed binary did not.

## Read-only triage commands

Do not mutate the DB unless the user explicitly asks. First prove whether the installed binary and source differ:

```bash
/home/semyon/.local/bin/t3 --version
python3 - <<'PY'
from pathlib import Path
p = Path('/home/semyon/.local/lib/node_modules/t3/dist/bin.mjs')
s = p.read_text(errors='ignore')
idx = s.find('case "item.updated"')
print('installed bin', p, 'idx', idx)
print(s[idx:idx+700] if idx != -1 else 'not found')
PY

git -C /home/semyon/code/external/t3code diff -- \
  apps/server/src/orchestration/Layers/ProviderRuntimeIngestion.ts \
  apps/server/src/orchestration/Layers/ProviderRuntimeIngestion.test.ts
```

Read DB shape and activity/event bulk read-only:

```bash
python3 - <<'PY'
import sqlite3, pathlib
DB = pathlib.Path('/home/semyon/.t3/userdata/state.sqlite')
con = sqlite3.connect(f'file:{DB}?mode=ro', uri=True)
cur = con.cursor()
print('DB_MB', round(DB.stat().st_size/1024/1024, 1))
for t in ['orchestration_events','projection_thread_activities','projection_thread_messages','projection_thread_proposed_plans','projection_turns']:
    print(t, cur.execute(f'SELECT count(*) FROM {t}').fetchone()[0])
print('\nactivity kind top:')
for row in cur.execute("SELECT kind, count(*), round(sum(length(payload_json))/1024.0/1024.0,1) mb FROM projection_thread_activities GROUP BY kind ORDER BY count(*) DESC LIMIT 15"):
    print(row)
print('\norchestration event types top:')
for row in cur.execute("SELECT event_type, count(*), round(sum(length(payload_json))/1024.0/1024.0,1) mb FROM orchestration_events GROUP BY event_type ORDER BY count(*) DESC LIMIT 15"):
    print(row)
print('\nprojection lag:')
maxseq = cur.execute('select max(sequence) from orchestration_events').fetchone()[0]
for row in cur.execute('select projector,last_applied_sequence, (? - last_applied_sequence) lag, updated_at from projection_state order by lag desc', (maxseq,)):
    print(row)
con.close()
PY
```

Also check the live process, but treat high RSS as a symptom, not proof of root cause:

```bash
pid=$(pgrep -f 'node /home/semyon/.local/bin/t3 serve' | head -n1)
ps -o pid,etime,stat,%cpu,%mem,rss,vsz,cmd -p "$pid" --no-headers
tr '\0' '\n' < /proc/$pid/environ | grep '^NODE_OPTIONS=' || true
```

## How to explain it to Semyon

Keep the answer practical and first-year-CS level:

- Node/V8 heap contains JS objects decoded from DB rows.
- Raising `--max-old-space-size` is a bigger bucket, not a fix.
- The real issue is state bloat plus unbounded snapshot/detail hydration.
- `tool.updated` spam is one smoking gun, but not the only bulk; `thread.message-sent` and `tool.completed` payloads can also dominate.
- Separate "installed binary behavior" from "local source checkout behavior"; the checkout may contain a fix that the service is not running.

Avoid claiming that DB cleanup alone is durable unless the installed binary no longer emits `tool.updated` and the snapshot/detail query behavior is understood.
