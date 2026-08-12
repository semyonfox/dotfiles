# T3 Code SQLite recovery, dedupe staging, and migration probes

Use this when Semyon is consolidating T3 Code state from `~/.t3`, old `~/.config/t3code` / AppData remnants, NAS/device dumps, or yoink-style staging trees.

## Core rule

Do **not** treat `~/.t3/userdata/state.sqlite` as disposable cache. It contains T3's projected thread list, message text, deleted/archive flags, runtime/session state, auth/pairing tables, turn state, orchestration events, and command receipts. Provider logs and Codex JSONLs are useful backups, but current T3 does not clearly rebuild a blank DB from provider logs alone.

## Safe consolidation shape

Keep live and recovery separate:

- live: `/home/semyon/.t3`
- recovery/staging: a timestamped `/home/semyon/t3-data-staging-<ts>`

Staging pass:

1. Copy candidate old data roots into staging, normalizing old Windows paths to Linux-style destinations where useful:
   - `/mnt/windows-ai/Users/foxsc` -> `/home/semyon`
   - `C:/Users/foxsc` -> `/home/semyon`
   - `C:\Users\foxsc` -> `/home/semyon`
2. Exclude `worktrees`, `.git`, `node_modules`, generated dependency trees, and empty app-cache skeletons unless explicitly requested.
3. Hash-dedup files inside staging.
4. Hash live roots such as `/home/semyon/.t3` and remove staged files that are exact duplicates of live.
5. Preserve manifests: copied sources, removed duplicates, DB merge reports, and checksums.

Writable empty NAS remnant dir trees can be removed after verifying they contain no files. Read-only snapshot paths may refuse deletion from the NFS client; report them as NAS-side snapshot pruning rather than fighting the mount.

## SQLite DB merge strategy

Never merge directly into live. Build candidate DBs and test on clones.

1. Inspect each DB's `effect_sql_migrations` and schema hash.
2. Group DBs by schema.
3. For same-schema DBs, create an empty copy of that schema and `INSERT OR IGNORE` by primary key from each source.
4. Remove rows already present in live from the candidate DB, again by primary key.
5. Skip `auth_sessions` and `auth_pairing_links` by default. They are stale/sensitive and not needed for recovering history.
6. Run:
   ```sql
   PRAGMA integrity_check;
   PRAGMA foreign_key_check;
   ```
7. Only then test against a cloned live DB.

## T3 migration insight from this session

Current T3 source has inline migrations in:

```text
apps/server/src/persistence/Migrations.ts
apps/server/src/persistence/Migrations/*.ts
```

The migration runner uses Effect SQL's `Migrator.make` / `Migrator.fromRecord`; normal app startup runs pending migrations through `makeSqlitePersistenceLive`.

Important observed schema groups:

- Current live schema through migration `032_AuthPairingProofKeyThumbprint`.
- Older 16-table schema through migration `030_ProjectionThreadShellArchiveIndexes` can be upgraded cleanly by running migrations `031_AuthAuthorizationScopes` and `032_AuthPairingProofKeyThumbprint` on a copied DB.
- Migration `031_AuthAuthorizationScopes` intentionally drops/recreates auth tables. This makes old auth/pairing rows disappear, which is acceptable for projection-history recovery but must be called out.
- A tiny/odd 40+ table DB with `effect_sql_migrations` containing `33 WorkflowSchema` is not simply "old and behind" if the current source only has migrations 1-32. Treat it as future/experimental/branch schema and keep it separate unless investigating specific workflow/ticket data.

## Proper migration probe pattern

Run migration probes only on copied DBs. With T3's Effect layers, provide platform services as well as persistence. A temporary script can import:

```ts
import * as Effect from "effect/Effect";
import * as Layer from "effect/Layer";
import { runMigrations } from "./src/persistence/Migrations.ts";
import { makeSqlitePersistenceLive } from "./src/persistence/Layers/Sqlite.ts";
```

Then provide Bun/Node services before running. Do not leave the helper script in the repo; delete it after the probe.

For live SQLite reads, avoid `immutable=1` when WAL files may contain current pages. Use `file:/path?mode=ro` so SQLite can read the WAL; otherwise schema/count inspection can falsely report a malformed DB.

## Canonical live import pattern

When Semyon explicitly approves making live canonical, still treat it as a controlled database migration, not a file copy.

1. Stop T3 cleanly first (`systemctl --user stop t3-code-headless.service`) and verify the port is closed before writing live.
2. Make a SQLite backup with the SQLite backup API, not a blind copy while WAL may be active. First checkpoint WAL, then backup, then verify `PRAGMA integrity_check` on the backup.
3. Dry-run the exact merge into a cloned live DB before touching live. Capture a JSON report with before/after counts, inserted rows, duplicate checks, integrity, FK checks, and errors.
4. Use the **current live schema** as the target, not an old staging schema. Keep `effect_sql_migrations` at the current source-supported max.
5. Do not import `projection_state` from staging. After importing events/projection rows, update live `projection_state.last_applied_sequence` to the final max event sequence so T3 does not reproject imported events over already-imported projection rows.
6. Restart T3 and verify:
   - service active
   - port/listener present
   - HTTP root or health endpoint returns 200
   - app startup logs show migrations ran with `migrations: []` or only expected pending migrations
   - DB `quick_check`/`integrity_check` remains OK

## Import dedupe pitfalls

T3 event data needs semantic dedupe, not just table primary-key copying:

- `orchestration_events.sequence` is a per-DB log position and collides across recovered DBs. When consolidating/importing events, dedupe by `event_id` and also respect the unique stream tuple `(aggregate_kind, stream_id, stream_version)`, then allocate fresh monotonically increasing live `sequence` values above the current live max.
- `orchestration_command_receipts.result_sequence` may point at old staging sequences after event remap. Re-link it by `command_id` to the new imported event sequence when possible.
- Add temp indexes on any event-import map (`event_id`, `command_id`) before merging command receipts. Without them, correlated receipt updates across hundreds of thousands of rows can look hung for many minutes.
- Normal projection tables can usually use `INSERT OR IGNORE` against primary keys / unique constraints. No-PK tables need full-row dedupe.
- Deduping a staging DB against live can strip `effect_sql_migrations` while leaving already-migrated columns in place. If a deduped staging DB has current schema but empty migration bookkeeping, patch `effect_sql_migrations` back to the source-supported migration rows before running a migrator; otherwise it may try migration 1 and fail with duplicate-column errors such as `runtime_mode`.

## Post-merge cleanup

Only after the live DB is verified and Semyon approves cleanup:

- Preserve the canonical live state directory (`/home/semyon/.t3/userdata/state.sqlite` plus active WAL/SHM), service config, and installed T3 binary/service machinery.
- Remove timestamped recovery/staging trees, yoink dumps, migration probe DBs, old schema artifacts, Hyperion/fork state when confirmed irrelevant, and one-off merge/probe scripts.
- Old live DB backups under `~/.t3/userdata` and huge internal `userdata/backups` / `userdata/logs` can be removed if explicitly approved; restart T3 afterwards so deleted logs are not held open.
- Re-verify service HTTP 200 and DB integrity after cleanup, then report disk space before/after plus the final canonical path.

## Report format for Semyon

Be blunt and operational:

- what is live/canonical
- what was staged or removed
- which schema groups are compatible
- which migrations ran
- whether integrity/FK/duplicate checks passed
- what is explicitly not being imported
- backup/rollback path, if still retained
- next safe command-level move

Avoid turning the chat into a giant forensic wall; attach diagrams/reports when useful and give the short verdict in Discord.