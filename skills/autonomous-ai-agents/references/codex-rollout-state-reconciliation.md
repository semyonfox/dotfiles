# Codex rollout state reconciliation and duplicate-session cleanup

Use when `codex doctor` reports stale rollout paths, files missing from the state DB, or duplicate rollout thread IDs after a Windows/Linux migration or an old session import.

## Principles

- `~/.codex/sessions/**/*.jsonl` is the durable source; `state_*.sqlite` is a rebuildable index.
- Do not make string-only path substitutions before proving each old thread ID maps to a real local rollout.
- Back up SQLite before any mutation. Preserve duplicate rollout originals in a rollback tree before removing them from active discovery paths.
- Do not delete non-identical transcript variants. Merge them into one canonical stream or retain them in the rollback archive.

## State-index repair

1. Run `codex doctor --no-color` and classify the discrepancy: stale DB path, DB rows absent for real files, malformed JSONL, or duplicate thread IDs.
2. Inspect `state_*.sqlite` read-only and map stale rows to local rollout files by **thread ID**, not filename alone.
3. If every stale row has an existing local counterpart, back up the database, remove only the obsolete rows and related stale spawn edges, then force Codex's normal index backfill:
   - set `backfill_state` to `pending` with a null watermark;
   - start one harmless read-only Codex session to trigger the upstream scanner;
   - verify the new rows point to current Linux paths and the files exist.
4. Do not manually fabricate metadata. Codex's own backfill extracts it from rollout contents and preserves the current schema.

Current upstream evidence: `codex-rs/state/migrations/0008_backfill_state.sql` creates the backfill marker. `codex-rs/rollout/src/metadata.rs::backfill_sessions_with_lease()` scans the session tree and upserts metadata. `recorder_tests.rs` verifies dropping truly missing paths and repairing stale paths when the rollout exists.

## Duplicate JSONL merge

For duplicate files sharing a session/thread ID:

1. Group by thread ID and select the un-suffixed file as canonical when present; otherwise choose the longest valid file.
2. Stage output outside `~/.codex/sessions`.
3. Preserve one canonical `session_meta` header, normalizing historical machine path variants to the current home path.
4. Normalize paths in all event bodies, dedupe exact normalized JSON events, and sort retained events by ISO timestamp with stable source/line ordering.
5. Keep records that differ beyond path normalization. They can contain divergent tool output or later context.
6. Validate every staged JSONL parses and every normalized input body event is represented in its merged output.
7. Back up every original variant to `~/.codex/repair-backups/<timestamp>/`, atomically replace only the canonical file, then remove only the redundant active variants.
8. Re-run `codex doctor`; the active rollout count and state DB row count should agree, with zero duplicate thread IDs.

## Pitfalls

- A completed `backfill_state` prevents a full scan; simply restarting Codex may not reconcile old imports.
- Duplicate records may be byte-identical or only differ by Windows/Linux path spelling. Normalize before deduplication.
- A duplicate filename suffix such as `--<hash>.jsonl` is not proof that the variant is disposable; assess event coverage first.
- `codex doctor` may be healthy even if a separately discovered old JSONL has a malformed line. Treat such files as a separate preservation/repair case, not as a reason to weaken successful reconciliation checks.
