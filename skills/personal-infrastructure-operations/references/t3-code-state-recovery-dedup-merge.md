# T3 Code state recovery, dedupe, and DB merge staging

Use when Semyon wants old T3 Code data/config recovered from yoink runs, NAS device dumps, snapshots, PC/laptop copies, or old Electron profile locations, especially before resetting or replacing `~/.t3`.

## Core truth

Do **not** treat T3 Code's live DB as disposable cache. The live DB at:

```text
/home/semyon/.t3/userdata/state.sqlite
```

contains projected UI/history state: projects, threads, messages, turns, provider runtime, orchestration events/receipts, auth sessions, pairing links, deleted/archive flags, etc. Provider logs and Codex/Claude/OpenCode raw logs may exist separately, but there is no known safe T3 CLI command that rebuilds a blank DB from provider logs. Resetting the DB loses the T3 thread list and projected message text unless exported or merged first.

## Current data path vs old/remnant paths

Repo/source evidence in T3 Code:

- `apps/server/src/os-jank.ts`: default base dir is `$HOME/.t3`.
- `apps/server/src/cli/config.ts`: precedence is `--base-dir`, `T3CODE_HOME`, bootstrap `t3Home`, then default.
- `apps/server/src/config.ts`: state path is `baseDir/userdata/state.sqlite`; dev mode can use `baseDir/dev/state.sqlite`.

For Semyon's server/headless service, verify process env first. If `T3CODE_HOME` is unset and `HOME=/home/semyon`, the real root is:

```text
/home/semyon/.t3
```

Old/remnant locations to inspect but not assume live:

```text
~/.config/t3code
~/.config/T3 Code (Alpha)
AppData/Roaming/t3code
~/.t3-code
~/.t3-code-hyperion
~/.local/state/t3code-data-backups
AppData/Local/Programs/t3code   # app install, not user data
```

## NAS and yoink scan pattern

Check these common backup roots before asking Semyon where old state lives:

```text
/home/semyon/ai-yoink-run-current -> usually symlink to the active consolidated yoink tree
/home/semyon/ai-yoink-run-*/
/mnt/media/users/semyon/device_dumps/
/mnt/media/snapshots/users/semyon/<snapshot>/device_dumps/
```

NAS current user-home device dumps may contain writable empty remnant dirs. If Semyon approves cleanup, delete only verified empty directory trees. Snapshot paths may be read-only over NFS; do not fight them from the client — note that they require NAS-side snapshot pruning.

## Safe staging workflow

When Semyon asks to bring old T3 data together:

1. **Do not modify live `~/.t3`.** Keep T3 running unless the user explicitly asks for a live import/replacement.
2. Create one staging root, e.g.:

   ```text
   /home/semyon/t3-data-staging-YYYYMMDD-HHMMSS
   ```

3. Copy candidate old sources into `sources/<source-name>/...` using real file copies, not symlinks.
4. Normalize paths to Linux-style locations in staging/manifests and later DB text fields:

   ```text
   /mnt/windows-ai/Users/foxsc        -> /home/semyon
   C:/Users/foxsc                     -> /home/semyon
   C:\Users\foxsc                    -> /home/semyon
   \\wsl.localhost\Ubuntu\home\semyon -> /home/semyon
   ```

5. Do not copy `worktrees/`, `.git/`, or `node_modules/` into the T3 state staging bundle unless explicitly requested.
6. First dedupe files within staging by `(sha256, size)`, deleting only duplicate staged copies.
7. Hash live roots such as `/home/semyon/.t3` and `/home/semyon/.t3-code-hyperion`; delete staged files only when an exact duplicate exists in live.
8. Produce manifests: copied sources, staged duplicate deletions, live duplicate deletions, SQLite merge summary, final size/counts.

## SQLite DB merge staging

For `state.sqlite` snapshots:

1. Group databases by exact schema hash. Do **not** merge different schemas into the same DB.
2. For each schema group, create an empty-schema copy and `INSERT OR IGNORE` rows from each source DB into the merged DB.
3. Remove original staged `state.sqlite`, `state.sqlite-wal`, and `state.sqlite-shm` after merged DB products exist, to avoid keeping duplicate DB rows/files in staging.
4. Compare merged DBs to live DB by primary key and delete rows already present in live from the staged merge DB. Keep old-only rows isolated.
5. Normalize Windows/WSL path strings in text columns after merge.
6. Verify every merged DB:

   ```sql
   PRAGMA integrity_check;
   PRAGMA foreign_key_check;
   ```

7. Keep schema groups separate, e.g.:

   ```text
   db/merged_schema_1.sqlite
   db/merged_schema_2.sqlite
   db/merged_schema_3.sqlite
   ```

The main useful same-schema merge is usually the current live-compatible schema group. It may contain old-only `projection_*` rows worth later import. Older schema groups are archive/recovery evidence unless a migration is written.

## What not to merge blindly

Do not broadly merge these into live:

```text
auth_sessions
auth_pairing_links
Cookies
DIPS
Local Storage/leveldb
IndexedDB
Electron/Chromium Cache, GPUCache, Code Cache
provider logs directly into DB
```

Auth/pairing rows are sensitive and often stale. Electron profile/LevelDB data is not safely binary-mergeable without app-aware export/import. Provider logs are useful forensic backup but not a known DB rebuild source.

## Live import, if requested later

Only after staging and review, if Semyon wants missing threads/messages imported:

1. Stop `t3-code-headless.service`.
2. Backup live `state.sqlite`, `state.sqlite-wal`, `state.sqlite-shm`, `logs/provider`, and attachments.
3. Import selected old-only projection rows into a copy first, not directly into live.
4. Skip auth/pairing rows unless doing a deliberate old-session resurrection.
5. Run integrity and FK checks.
6. Start T3 against the test/merged copy if possible; otherwise restore/replace live only with explicit approval.
7. Verify the UI/API shows expected recovered threads before deleting any staging/archive data.

## Reporting

Lead with locations and what was or was not modified:

- real live root
- staging root
- number of sources copied
- staged DBs merged by schema group
- duplicate staged files removed
- exact staged-vs-live duplicates removed
- integrity/FK check result
- whether live T3 was modified

Stop after staging if the user asked to “stop then we’ll pick up then.”
