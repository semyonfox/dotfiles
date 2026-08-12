# T3 Code data-location and recovered-state merge audit

Use when Semyon asks whether old/recovered T3 Code config or databases can be merged into the real current T3 state, especially after `ai-yoink`/device-dump/NAS recovery work.

## Current data-location truth

For the active T3 Code server, read the repo and live process first instead of guessing from old Electron paths.

Relevant source files in the T3 Code repo:

- `apps/server/src/os-jank.ts` — `resolveBaseDir()` defaults to `$HOME/.t3` when no override is provided.
- `apps/server/src/cli/config.ts` — `T3CODE_HOME`, `--base-dir`, and desktop bootstrap `t3Home` override the default.
- `apps/server/src/config.ts` — derived state paths are `baseDir/userdata/*`; DB is `baseDir/userdata/state.sqlite`; dev mode with `VITE_DEV_SERVER_URL` uses `baseDir/dev/*`.
- `packages/ssh/src/tunnel.ts` — remote/SSH launch defaults also assume `$HOME/.t3`.

For Semyon's server/headless service, verify the live process/service env:

```bash
systemctl --user status t3-code-headless.service --no-pager
pid=$(pgrep -u "$USER" -f '/home/semyon/.local/bin/t3 serve' | head -1)
tr '\0' '\n' < /proc/$pid/environ | grep -E '^(T3CODE_HOME|T3CODE_MODE|T3CODE_PORT|T3CODE_HOST|T3CODE_NO_BROWSER|HOME|PWD)='
```

If `T3CODE_HOME` is unset and `HOME=/home/semyon`, the real root is:

```text
/home/semyon/.t3
/home/semyon/.t3/userdata/state.sqlite
```

## Old/remnant locations

Treat these as old/remnant locations unless the live process explicitly points there:

```text
~/.config/t3code
~/.config/T3 Code (Alpha)
AppData/Roaming/t3code
~/.t3-code
~/.t3-code-hyperion
~/.local/state/t3code-data-backups
```

`AppData/Local/Programs/t3code` is an app install, not user state.

Old `.config/t3code` / `AppData/Roaming/t3code` trees are usually Chromium/Electron profile/cache state (`Cache`, `GPUCache`, `DIPS`, `Cookies`, `Local Storage/leveldb`, `IndexedDB`). Do **not** binary-merge them into `~/.t3`; only inspect them as archive/profile evidence.

## NAS / device-dump places to check

Check both current user device dumps and snapshots, bounded to known roots to avoid crawling all media:

```text
/mnt/media/users/semyon/device_dumps/windows_pc/.t3
/mnt/media/users/semyon/device_dumps/windows_pc/dotfiles/.t3
/mnt/media/users/semyon/device_dumps/windows_pc/AppData/Roaming/t3code*
/mnt/media/users/semyon/device_dumps/windows_pc/AppData/Local/Programs/t3code
/mnt/media/users/semyon/device_dumps/linux-laptop/full-home-current/.t3
/mnt/media/users/semyon/device_dumps/linux-laptop/full-home-current/.config/t3code
/mnt/media/users/semyon/device_dumps/linux-laptop/full-home-current/.config/T3 Code (Alpha)
/mnt/media/users/semyon/device_dumps/linux-laptop/dotfiles/.t3
/mnt/media/users/semyon/device_dumps/linux-laptop/dotfiles/.config/t3code
/mnt/media/users/semyon/device_dumps/linux-laptop/dotfiles/.config/T3 Code (Alpha)
/mnt/media/snapshots/users/semyon/<snapshot>/device_dumps/...
```

Recent NAS snapshots may preserve directory names while pruning contents; verify file counts and `du`, not just path existence.

## Read-only DB comparison pattern

Never attach/write the live DB. Use immutable/read-only SQLite connections or copies in an analysis directory.

Key tables to compare by primary key:

```text
projection_projects(project_id)
projection_threads(thread_id)
projection_thread_messages(message_id)
projection_thread_sessions(thread_id)
projection_turns(turn_id)
provider_session_runtime(thread_id)
auth_sessions(session_id)
auth_pairing_links(id)
```

Useful read-only probe:

```python
import sqlite3, pathlib
p = pathlib.Path('/home/semyon/.t3/userdata/state.sqlite')
con = sqlite3.connect(f'file:{p}?mode=ro&immutable=1', uri=True, timeout=5)
cur = con.cursor()
for (t,) in cur.execute("select name from sqlite_master where type='table' order by name"):
    print(t, cur.execute(f'select count(*) from "{t}"').fetchone()[0])
```

Compare candidate DBs to live by key intersection and candidate-only counts. Candidate-only projection rows can represent recoverable old conversations/projects; auth rows usually represent stale/sensitive sessions.

## Merge guidance

Default recommendation: **do not merge automatically**.

Safe-ish to ignore:

- Empty NAS `.t3` or `.config/t3code` remnants.
- Chromium/Electron profile/cache trees.
- Provider logs where live is already a byte-prefix superset of recovered logs.
- Old auth/session/pairing rows unless the user explicitly wants session resurrection.

Potentially worth a targeted import:

- Candidate-only projection rows from old `~/.t3/userdata/state.sqlite` copies: projects, threads, messages, sessions, turns, runtime rows.

If the user wants those recovered, use a proper stopped-service migration:

1. Stop `t3-code-headless.service` and any desktop T3 processes for the target machine.
2. Back up live `~/.t3/userdata/state.sqlite`, `-wal`, and `-shm` if present.
3. Build a temporary merge DB first; do not edit live directly.
4. Insert only missing projection rows by primary key, preserving referential relationships.
5. Skip `auth_sessions` and `auth_pairing_links` by default.
6. Run `PRAGMA integrity_check` and count checks.
7. Swap/apply only with explicit approval, then restart T3 and verify UI/API.

## Pitfalls

- Do not infer the current data root from old `.config/t3code` or Electron profile paths. The repo and live process usually point to `~/.t3`.
- Do not touch T3 worktrees during data recovery audits unless the user explicitly asks; Semyon may be actively using them.
- Do not paste secrets, pairing links, cookies, auth DB rows, or token-bearing JSON into chat. Report counts, paths, table names, timestamps, and redacted summaries only.
- Large copied SQLite DBs in analysis directories can consume many GB. Delete temporary DB copies after extracting JSON/CSV summaries unless the user asks to keep them.
