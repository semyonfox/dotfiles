# T3 SQLite consolidated staging archives

Use when Semyon asks to consolidate recovered T3 Code `state.sqlite` databases while keeping live untouched.

## Core rules

- Never mutate `~/.t3/userdata/state.sqlite` directly. Use it read-only for current schema and duplicate detection.
- Work under a timestamped staging directory and make separate outputs for different semantics:
  - **all-unique archive**: all unique rows from recovered/staging DBs, deduped between sources, not deduped against live.
  - **live-delta archive**: only rows not already present in live; better eventual import candidate.
- Keep reports as JSON next to the generated DBs with exact source paths, row counts, skipped tables, errors, and verification.
- `VACUUM` final archives so the result is compact.

## Repairing already-deduped staging DBs

A prior live-dedupe pass may remove `effect_sql_migrations` rows while leaving the schema itself already migrated. If the T3 migrator then fails with an already-existing column such as:

```text
SQLiteError: duplicate column name: runtime_mode
```

check whether the schema object set already matches current live. If it does, patch only migration bookkeeping by copying current live `effect_sql_migrations` rows into the staging DB. Then re-run integrity/schema checks. Do not re-run app migrations blindly against a DB with migrated columns and empty migration history.

## Merge/dedup keys

- Normal tables: dedup by primary key (`thread_id`, `message_id`, `session_id`, `command_id`, etc.).
- No-primary-key tables such as `checkpoint_diff_blobs`: dedup by full-row equality.
- `orchestration_events`: **do not dedup by `sequence`**. `sequence` is per-source and collides across recovered DBs. Dedup semantically by `event_id`, then remap `sequence` monotonically in the consolidated archive.
- `orchestration_command_receipts`: dedup by `command_id`.

## Tables to skip or regenerate

- `effect_sql_migrations`: create from the current schema/migration state, not from sources.
- `projection_state`: skip/import-regenerate later. It stores projector offsets tied to source event sequences; after event sequence remapping, imported offsets are misleading.
- Auth tables (`auth_sessions`, `auth_pairing_links`) are usually stale. Preserve in staging reports if requested, but do not import to live without explicit approval.

## WorkflowSchema / future-branch DBs

Some old T3 staging DBs may have `33 WorkflowSchema` and many extra workflow/ticket tables (`workflow_events`, `projection_ticket`, `worktree_lease`, etc.) while current source only has migrations through 32. Treat these as future/branch artifacts, not normal old DBs. Import only common current-schema tables into current-schema consolidated archives, and report any non-empty extra workflow tables separately.

## Verification before reporting success

Run and record:

```sql
PRAGMA integrity_check;
PRAGMA foreign_key_check;
```

Also verify:

- duplicate primary-key group count is zero for every PK table;
- duplicate `orchestration_events.event_id` group count is zero;
- output schema matches the intended current target schema;
- merge error count is zero, or every error is explicitly reported with source/table/stage;
- live DB was read-only and not modified.

## Reporting shape

Keep the chat summary short:

- paths for all-unique and live-delta DBs;
- report JSON paths;
- integrity/fk/duplicate checks;
- compact row-count highlights;
- what did not update/merge and why;
- explicit statement that live was not touched.
