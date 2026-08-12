# T3 Code state DB triage without reset

Use this when debugging T3 Code / similar stateful local agent GUIs where the user reports connectivity or pairing issues and mentions that a DB reset fixes it, but the DB contains valuable session/project state.

## Safe investigation pattern

1. **Do not touch the live SQLite DB first.** Copy `state.sqlite` plus any `-wal`/`-shm` files into `/tmp` or another scratch location and inspect the copy.
2. **Resolve the actual state root.** Upstream/default T3 Code resolves `T3CODE_HOME` / `--base-dir`, otherwise `~/.t3`. Desktop/server paths derive:
   - `<baseDir>/userdata/state.sqlite` for normal runs
   - `<baseDir>/dev/state.sqlite` when a dev URL is configured
   - `<baseDir>/userdata/{attachments,logs,secrets}`
   - `<baseDir>/worktrees`
3. **Check aliases/symlinks before blaming drift.** `~/.t3 -> ~/.t3-code` can be harmless if the running server explicitly uses `--base-dir ~/.t3-code` and all paths resolve to the same directory.
4. **Compare schema against expected state instead of guessing.** Clone upstream or use the installed CLI against a disposable `--base-dir`, let migrations run, then compare tables/columns/indexes/migration rows with the copied live DB.
5. **Separate schema drift from auth/runtime projection state.** If schema, indexes, migrations, and `PRAGMA integrity_check` are clean, reset fixes are often wiping poisoned auth/pairing/runtime rows rather than repairing tables.
6. **Read logs/traces for live failures.** Search recent server/desktop traces for SQLite errors, auth/pairing failures, websocket 401s, migration failures, and provider/runtime resume errors.

## Useful probes

```bash
# Identify actual running base dir / port / process
ps -eo pid,ppid,etime,cmd | grep -E 't3|t3code|3773' | grep -v grep
ss -ltnp | grep -E ':3773|:3774|:3775' || true

# Check state-dir aliases
for p in "$HOME/.t3" "$HOME/.t3-code"; do
  [ -e "$p" ] || [ -L "$p" ] && printf '%s -> %s\n' "$p" "$(readlink -f "$p")"
done

# Create expected disposable state from installed CLI; timeout exit is okay after migrations
EXPECTED=/tmp/t3-expected-$(date +%Y%m%d-%H%M%S)
mkdir -p "$EXPECTED"
timeout 8s t3 serve --host 127.0.0.1 --port 3799 --base-dir "$EXPECTED" --no-browser /tmp \
  >/tmp/t3-expected-run.log 2>&1 || true
```

Python schema comparison sketch:

```python
import pathlib, shutil, sqlite3, time
src = pathlib.Path.home()/'.t3-code/userdata'
snap = pathlib.Path('/tmp')/('t3-state-snapshot-'+time.strftime('%Y%m%d-%H%M%S'))
snap.mkdir()
for name in ['state.sqlite', 'state.sqlite-wal', 'state.sqlite-shm']:
    if (src/name).exists(): shutil.copy2(src/name, snap/name)

conn = sqlite3.connect(str(snap/'state.sqlite'))
print(conn.execute('PRAGMA integrity_check').fetchone()[0])
for row in conn.execute("SELECT type,name,tbl_name FROM sqlite_master WHERE type IN ('table','index','view','trigger') ORDER BY type,name"):
    print(row)
```

## Pitfalls

- Do **not** rename tables or columns just because reset helps. First prove schema mismatch against a clean expected DB.
- Do **not** run migrations/cleanup directly against the live DB while the user is actively working.
- SQLite CLI may not be installed; Python `sqlite3` is often enough for read-only inspection of snapshots.
- Expired/unconsumed pairing links, stale client local storage, revoked/missing sessions, or websocket 401s can look like connectivity even when the server and DB schema are healthy.
- Large event/projection tables are not corruption by themselves; treat them as performance/context, not evidence.
