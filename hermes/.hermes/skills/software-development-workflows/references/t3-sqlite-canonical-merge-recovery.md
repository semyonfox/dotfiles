# T3 SQLite canonical merge recovery

Use when consolidating multiple recovered T3 Code `state.sqlite` files into the live canonical DB. This is the destructive/live phase after earlier staging/migration/dedupe work.

## Safe sequence

1. **Take T3 offline first**
   - Stop the user service if present: `systemctl --user stop t3-code-headless.service`.
   - Verify `:3773` is no longer listening and no `t3 serve` process still owns the DB.

2. **Make a verified SQLite backup before writes**
   - Checkpoint WAL first: `PRAGMA wal_checkpoint(TRUNCATE);`.
   - Prefer SQLite backup API over raw copy when a WAL may exist.
   - Verify backup with `PRAGMA integrity_check;` and basic table counts.

3. **Exclude known irrelevant forks**
   - Hyperion / `WorkflowSchema` fork DBs with migration `33 WorkflowSchema` are not current T3 schema and should be excluded from canonical live merge unless the user explicitly asks to preserve that branch data. In the observed case the workflow-only tables were empty and irrelevant.

4. **Dry-run into a cloned live DB**
   - Copy the verified backup to a dry-run target.
   - Merge the staging delta into the clone.
   - Verify: `integrity_check`, `foreign_key_check`, no duplicate PK groups, no duplicate `orchestration_events.event_id` groups, expected row-count deltas.

5. **Merge event logs carefully**
   - `orchestration_events.sequence` is per-DB and collides across recovered DBs; do not use it as the cross-DB identity.
   - Deduplicate events by `event_id` **and** by the T3 unique stream triple: `(aggregate_kind, stream_id, stream_version)`.
   - Remap imported `sequence` values above the current live max sequence.
   - Re-link `orchestration_command_receipts.result_sequence` to the remapped event sequence by `command_id` where possible.
   - Add temp indexes on remap tables (`command_id`, `event_id`) before receipt relinking; otherwise correlated lookups over hundreds of thousands of rows can take forever.

6. **Projection state after importing projections and events**
   - If projection rows are imported directly alongside event rows, advance `projection_state.last_applied_sequence` to the final max event sequence. Otherwise T3 may try to re-project already-imported events and duplicate/conflict with projection rows.
   - Do not import `projection_state` from recovered DBs; it is projector bookkeeping tied to a specific source event sequence.

7. **Apply to live only after dry-run passes**
   - Re-check T3 is still offline.
   - Run the exact merge script against `/home/semyon/.t3/userdata/state.sqlite`.
   - Verify the same checks on live.

8. **Restart and verify service health**
   - Start `t3-code-headless.service`.
   - Check service active, `:3773` listening, HTTP root returns 200, and logs show migrations `[]` or otherwise successful.
   - Provider warnings such as Grok CLI health check failure are separate from DB merge health unless accompanied by DB errors.

## Pitfalls observed

- Deduped staging DBs may have current schemas but empty `effect_sql_migrations`; patch migration bookkeeping to rows `1..32` before treating them as current-schema T3 DBs. Otherwise the migrator reruns old migrations and fails on existing columns like `runtime_mode`.
- Do not import Hyperion/WorkflowSchema fork tables into canonical current live unless explicitly required; they are branch/future schema, not normal old T3 history.
- Full archive and live-delta DBs serve different purposes: keep an `all_unique` archive for provenance, but use a `delta` DB for live import to avoid re-importing rows already canonical.
