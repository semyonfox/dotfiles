# T3 Code migration and recovered-state merge preflight

Use after finding a retained `~/.t3` copy and before any live T3 state import.

## Safety boundary

- Treat live `~/.t3/userdata/state.sqlite` plus `-wal`/`-shm` as active state. Read it only while T3 runs.
- Copy the recovered DB **and its WAL/SHM** into a local timestamped audit root; do not migrate the NAS/archive source in place.
- Run latest T3 only against the copied base dir on `127.0.0.1` and a spare port. Stop the isolated process after it has migrated and listened successfully.
- T3's headless startup prints a pairing URL/token and QR. Do not retain raw logs; redact the token/URL immediately.

Example isolated migration:

```bash
# candidate base contains userdata/state.sqlite (+ optional WAL/SHM)
timeout -s INT -k 10s 35s t3 serve \
  --base-dir "$candidate" --host 127.0.0.1 --port 3774 --no-browser /home/semyon \
  >"$audit/migration.log" 2>&1
```

Confirm the log says `Migrations ran successfully`, then use read-only SQLite checks:

```sql
PRAGMA integrity_check;
PRAGMA foreign_key_check;
SELECT migration_id, name
FROM effect_sql_migrations
ORDER BY migration_id DESC LIMIT 1;
```

## Schema interpretation

Compare table names and `PRAGMA table_info(table)` before comparing content. A current T3 runtime can migrate a recovered DB to the latest standard migrations while live still contains a local helper/audit table. Do **not** add such a table merely to force schema equality. In particular, `t3_project_merge_audit` may document historical canonicalization in live state rather than represent recoverable user data.

## Content preflight: no duplicates, paths are metadata

Use IDs as merge keys; report counts only, never message text, auth credentials, pairing data, or raw paths unless specifically needed.

Typical keys:

| Table | Key |
|---|---|
| `projection_projects` | `project_id` |
| `projection_threads`, `projection_thread_sessions`, `provider_session_runtime` | `thread_id` |
| `projection_thread_messages` | `message_id` |
| `projection_thread_activities` | `activity_id` |
| `projection_thread_proposed_plans` | `plan_id` |
| `projection_pending_approvals` | `request_id` |
| `orchestration_command_receipts` | `command_id` |
| `orchestration_events` | `event_id` |

`workspace_root` and `worktree_path` are descriptive metadata. Compare them only to flag same-ID differences; do not use them to dedupe and do not overwrite canonical live paths during an import without a separate approved path migration.

### Turn-row pitfall

`projection_turns.row_id` is the database PK, but `turn_id` is the useful cross-copy identity when populated. A `NULL turn_id` never equals another `NULL` in a normal SQL equality join, so it can falsely look source-only. For null-ID turn rows, compare the stable row ID and/or all non-row-ID semantic fields with NULL-safe equality before treating a row as missing. Do not blindly insert such rows.

### Project-merge evidence

If an archived project ID is absent from `projection_projects` but appears as `merged_project_id` in live `t3_project_merge_audit`, and a live canonical project has the same workspace root, treat it as already consolidated. Do not resurrect the old project or move threads back.

## Decision rule

If all recovered rows are already represented in live by stable keys or semantic equivalence, **do not merge**. Keep the recovered tree as archive evidence. A live merge is justified only by verified source-only projection data, after a stopped-service backup and a successful copy-first UI/API verification.
