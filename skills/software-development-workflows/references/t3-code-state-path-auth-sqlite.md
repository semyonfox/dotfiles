# T3 Code state path, auth, and duplicate-row triage

Use this when debugging T3 Code connectivity, pairing, startup, or suspected SQLite corruption without destroying user state.

## Core model

- T3's default base dir is `~/.t3`; `T3CODE_HOME` or `--base-dir` overrides it.
- Derived production state lives under `<baseDir>/userdata/`:
  - `state.sqlite` plus WAL/SHM sidecars
  - `attachments/`, `logs/`, `secrets/`, settings JSON files
- Dev mode uses `<baseDir>/dev/` instead of `userdata/`.
- Worktrees live at `<baseDir>/worktrees/`.

## Safe investigation order

1. Identify the real base directory and aliases:
   - `readlink -f ~/.t3 ~/.t3-code 2>/dev/null`
   - inspect `T3CODE_HOME`, `--base-dir`, systemd units, launcher scripts, and process args.
2. Check for duplicate writers before blaming SQLite:
   - one `t3 serve` process per base dir;
   - one listener per intended port;
   - beware old desktop/headless/dev processes using aliased dirs.
3. Do not open/edit the live SQLite DB directly while the server is running unless the task is read-only and low risk. Prefer copying `state.sqlite`, `state.sqlite-wal`, and `state.sqlite-shm` to a temp snapshot for schema/duplicate analysis.
4. Compare expected schema by starting the same installed `t3` version against a disposable `--base-dir` and comparing tables/columns/indexes/migration rows to the snapshot.
5. Treat schema match + `PRAGMA quick_check`/`integrity_check` OK as evidence against table-name/schema drift. Look next at auth/pairing/runtime rows and client local state.

## Path canonicalization pattern

When `.t3` and `.t3-code` alias the same state and the user wants it cleaned up:

1. Stop the user service / all `t3 serve` processes cleanly.
2. Back up service files, launcher scripts, and DB sidecars.
3. Pick one canonical real directory. Prefer `~/.t3` for the main instance because it matches upstream defaults.
4. Remove the symlink and move the real directory into place.
5. Patch systemd units and launcher scripts for the canonical path:
   - if the canonical main dir is `~/.t3`, prefer dropping explicit `T3CODE_HOME`/`--base-dir` so the service uses upstream defaults naturally;
   - if the canonical dir is anything else, keep `T3CODE_HOME`/`--base-dir` explicit.
6. Do **not** leave a compatibility symlink if the goal is to flush stale references; fail-fast is better than hidden aliasing.
7. Restart and verify service status, process command line, HTTP response, path shape, and DB quick_check. When checking process args, avoid grepping your own verification command and inspect `/proc/<pid>/cmdline` for real `t3 serve` processes if necessary.

Keep separate dev instances explicitly separate, e.g. `~/.t3-code-hyperion`, rather than folding them into the main state.

## Structural/rot scan pattern

When the user asks whether the DB is structurally current or rotten, separate hard integrity from semantic stale state:

- Compare live/copied schema to a disposable clean DB created by the same installed `t3` version; require tables, columns, indexes, and migrations to match before saying it is current.
- Run `PRAGMA quick_check`/`foreign_key_check` and logical orphan checks across projections: threads without projects, messages/activities/turns/sessions/runtime without threads, pending approvals without threads.
- Check projection catch-up by comparing every `projection_state.last_applied_sequence` to `MAX(orchestration_events.sequence)`.
- Validate JSON columns with `json_valid` for settings/scopes/payload fields before blaming parser breakage.
- Look for semantic stale state separately: deleted threads with running sessions, runtime rows for deleted threads, active sessions with `active_turn_id`, stale `last_error`, huge repeated runtime warnings, and active projects whose workspace roots are missing or not Git repos.
- Correlate with recent service logs. Repeated provider health check failures, VCS remote-status timeouts, or SSH/tunnel churn can make the UI look disconnected even when the SQLite schema is perfect.

## Auth cleanup pattern

For connectivity/pairing issues, reset is overkill. A safe narrow cleanup is deleting only expired, unused pairing links:

```sql
DELETE FROM auth_pairing_links
WHERE revoked_at IS NULL
  AND consumed_at IS NULL
  AND datetime(expires_at) <= datetime('now');
```

Before and after, count:

```sql
SELECT COUNT(*) FROM auth_pairing_links
WHERE revoked_at IS NULL
  AND consumed_at IS NULL
  AND datetime(expires_at) <= datetime('now');
```

Do not delete active sessions, consumed links, or runtime/session rows unless the user explicitly asks and you have a rollback backup.

## Duplicate scan pattern

Analyze duplicates without changing data:

- Exact table duplicates excluding identity columns/PKs for projection and orchestration tables.
- Same project + same thread title groups.
- Near-duplicate thread creations in a short window, e.g. 10 minutes.
- Duplicate `latest_turn_id` across threads.
- Duplicate `provider_session_id` across thread sessions.
- Exact duplicate messages by `(thread_id, role, text, created_at)`.
- Event/receipt command duplication, but remember multiple events per command can be normal.

If the only findings are separate thread IDs with the same title and all are deleted, report them as duplicate-looking creation attempts, not corruption.

## Reporting

For Semyon, keep the summary operational and blunt:

- what was changed;
- backup path;
- verification output;
- what was only analyzed and not modified;
- whether the evidence points to schema corruption, auth/session state, duplicate writers, or harmless duplicate-looking rows.
