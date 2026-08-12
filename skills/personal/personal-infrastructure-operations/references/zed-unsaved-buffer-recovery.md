# Zed unsaved buffer recovery over SSH

Use when Semyon says a project exists on another fleet machine and the visible files are stale because edits were in Zed or an embedded terminal/editor and never saved.

## Pattern

1. **Do not assume the on-disk file is the latest copy.** First inspect the target machine over SSH for live editor processes and editor state.
2. Check for live `nvim`/`vim` processes and swap files:

```bash
ssh <host> 'ps -eo pid,ppid,tty,stat,lstart,cmd | grep -E "[n]vim|[v]im" || true; find ~/.local/state/nvim/swap ~ -name ".*.swp" -o -name ".*.swo" 2>/dev/null | head'
```

3. For Zed, inspect the stable workspace database. Zed may persist unsaved buffer contents in:

```text
~/.local/share/zed/db/0-stable/db.sqlite
```

Useful tables:

```sql
.schema editors
.schema items
SELECT e.workspace_id,e.item_id,i.active,i.position,e.buffer_path,e.language,length(e.contents),substr(e.contents,1,160)
FROM editors e
LEFT JOIN items i ON i.workspace_id=e.workspace_id AND i.item_id=e.item_id
WHERE e.contents IS NOT NULL OR e.buffer_path LIKE '%PROJECT_OR_FILE%'
ORDER BY e.workspace_id DESC, i.position;
```

4. If the wanted unsaved buffer is present, extract it with Python/sqlite, **back up the stale file first**, then write the recovered contents:

```bash
ssh <host> 'python - <<"PY"
import sqlite3, pathlib, shutil, time
zed_db = pathlib.Path("/home/semyon/.local/share/zed/db/0-stable/db.sqlite")
target = pathlib.Path("/home/semyon/code/personal/go-expenses/main.go")
backup = target.with_suffix(target.suffix + ".pre-zed-recovery-" + time.strftime("%Y%m%d-%H%M%S"))
con = sqlite3.connect(str(zed_db))
row = con.execute("select contents from editors where buffer_path=?", (str(target),)).fetchone()
if not row or row[0] is None:
    raise SystemExit("No Zed unsaved contents found for target")
shutil.copy2(target, backup)
target.write_text(row[0], encoding="utf-8")
print(f"wrote {target} from Zed db ({len(row[0])} bytes)")
print(f"backup {backup}")
PY'
```

5. Verify with a safe readback (`wc -c`, `sed -n`, project build/test if tooling exists), then copy/sync to the destination device if requested.

## Pitfalls

- `ps` showing no `nvim` does **not** mean the work is lost if Zed has the file open; check Zed's DB before giving up.
- Do not kill Zed or terminals during recovery. Read the DB and copy out contents first.
- Do not overwrite without creating a timestamped backup of the stale on-disk file.
- If build/test fails because functions were not written yet, report that as separate from recovery success. The goal is rescuing the unsaved buffer, not making unfinished code compile.
