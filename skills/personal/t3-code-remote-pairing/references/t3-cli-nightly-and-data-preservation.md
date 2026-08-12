# T3 CLI channel and data-preservation recovery

Use this when T3 Code appears to have lost config, projects, threads, or auth after reinstalling/updating the CLI or desktop app.

## Key lesson

`npm install -g t3@latest` is not necessarily the same channel as Semyon's `t3code-nightly-bin` desktop app. At the time this was discovered, npm dist-tags were:

```text
latest  = 0.0.28
nightly = 0.0.29-nightly.20260707.751
```

If the desktop app is on `t3code-nightly-bin`, prefer:

```bash
npm --prefix ~/.local install -g t3@nightly
~/.local/bin/t3 --version
npm view t3 dist-tags --json
```

Run this per reachable device (`server`, `pc`, `nas`, `laptop` when online). If an old user-local symlink blocks install, inspect it and use scoped `--force`; if native build tooling is missing and only optional native modules fail, retry with `--ignore-scripts` and verify the binary runs.

## Do not restore first

When Semyon asks whether data is gone, treat restore as a later option. First inspect live state read-only:

```bash
ssh pc 'du -sh ~/.t3 ~/.config/t3code 2>/dev/null; ls -lh ~/.t3/userdata/state.sqlite* 2>/dev/null'
```

Then query SQLite read-only:

```bash
python3 - <<'PY'
import sqlite3
from pathlib import Path
DB = Path.home()/'.t3/userdata/state.sqlite'
con = sqlite3.connect(f'file:{DB}?mode=ro', uri=True)
cur = con.cursor()
print('integrity', cur.execute('PRAGMA integrity_check').fetchone()[0])
for table in ['projection_projects','projection_threads','projection_thread_messages','projection_thread_activities','projection_turns','auth_sessions']:
    try:
        print(table, cur.execute(f'SELECT count(*) FROM {table}').fetchone()[0])
    except Exception as e:
        print(table, 'ERR', e)
con.close()
PY
```

Healthy signs: non-empty `~/.t3`, non-empty `~/.config/t3code`, `integrity ok`, and non-zero projection tables. That usually means a channel/schema/UI mismatch rather than deletion.

## Preserve before any fix/restore

Before rolling back, copying old backups over live state, or considering Btrfs/snapper, create a plain filesystem preservation bundle:

```bash
stamp=$(date +%Y%m%d-%H%M%S)
out="$HOME/t3-data-preserve-$stamp"
mkdir -p "$out"
python3 - <<PY
import sqlite3, shutil
from pathlib import Path
home=Path.home(); out=home/'t3-data-preserve-$stamp'
db=home/'.t3/userdata/state.sqlite'
if db.exists():
    src=sqlite3.connect(f'file:{db}?mode=ro', uri=True)
    dst=sqlite3.connect(out/'state.sqlite.backup')
    src.backup(dst); dst.close(); src.close()
for rel in ['.t3/userdata/settings.json', '.t3/userdata/keybindings.json', '.t3/userdata/client-settings.json', '.t3/userdata/desktop-settings.json', '.t3/userdata/saved-environments.json', '.t3/userdata/connection-catalog.json']:
    p=home/rel
    if p.exists(): shutil.copy2(p, out/rel.replace('/', '__'))
PY
mkdir -p "$out/config-t3code"
for item in 'Preferences' 'Local State' 'Network Persistent State' 'Cookies' 'Local Storage' 'IndexedDB' 'Session Storage' 'Partitions'; do
  [ -e "$HOME/.config/t3code/$item" ] && cp -a "$HOME/.config/t3code/$item" "$out/config-t3code/" || true
done
printf 'backup_path=%s\n' "$out"
```

Only after that should you restore older backups such as `~/auth_config_backup_*/.t3` or consider Btrfs/snapper snapshots.
