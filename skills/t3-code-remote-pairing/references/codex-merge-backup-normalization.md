# Codex merge-backup normalization and safe merge workflow

Use this when Semyon asks whether `~/.codex-merge-backup` is deletable, whether its rollouts are contained in `~/.codex`, or asks to merge old Codex rollout variants into the live/session training corpus.

## Core lesson

`~/.codex-merge-backup/<stamp>/replaced-root/**/*.jsonl` can contain old versions of rollout files that have the same relative paths as current `~/.codex/sessions/**/*.jsonl` but different content. Do not decide deletability from filenames alone.

In the 2026-07-11 case:

- Backup: `~/.codex-merge-backup/20260707-224135`
- Replaced rollout files: 178
- Backup old lines: 66,115
- Current lines before merge: 67,494
- Normalized merged lines: 68,518
- Unique normalized records recovered from backup/current union: 1,024
- Exact normalized duplicates collapsed: 64,907
- Semantic conflict keys preserved as variants: 1,007

## Investigation steps

1. Inspect the backup manifest first:

   ```bash
   python3 - <<'PY'
   import json
   from pathlib import Path
   m = json.loads(Path.home().joinpath('.codex-merge-backup/20260707-224135/manifest.json').read_text())
   for k in ['copied_new','replaced','skipped_deleted','source_duplicate_deleted','errors','removed_empty_dirs_count']:
       v = m.get(k)
       print(k, len(v) if isinstance(v, list) else v)
   PY
   ```

2. Compare backup files to current by content hash and by relative path. Same filename/path is not enough: old/current often differ only by path normalization, but sometimes have appended tool calls or extra turns.
3. Parse both sides as JSONL before touching live files. Abort on parse errors in affected files.
4. Inspect event structure. Codex rollout records are usually:

   ```json
   {"timestamp":"...","type":"session_meta|event_msg|response_item|turn_context|compacted","payload":{}}
   ```

   Useful keys are `payload.call_id`, `payload.turn_id`, `payload.id`, `payload.role`, `payload.content`, and `timestamp`.

## Safe merge policy

Do not blindly append old backup lines to current rollout files. Merge into a staging directory first and validate.

Recommended policy for live `~/.codex/sessions` merges:

- Normalize known workstation path roots to current Linux paths:
  - `C:\\Users\\foxsc` -> `/home/semyon`
  - `C:/Users/foxsc` -> `/home/semyon`
  - `\\\\?\\C:\\Users\\foxsc` -> `/home/semyon`
  - `/mnt/c/Users/foxsc` -> `/home/semyon`
  - mixed `/home/semyon\\...` -> `/home/semyon/...`
- Prefer current records for exact normalized duplicates.
- Keep old backup body records that remain unique after normalization.
- Do **not** inject backup `session_meta` headers. Keep current session headers, because some current files are already multi-session/concatenated and extra headers make runtime archaeology worse.
- If the same semantic key differs beyond path normalization, keep both variants rather than dropping one; training data should preserve potentially meaningful tool output differences.
- Never mutate `~/.codex/state_5.sqlite` for this merge unless there is a separate, explicit DB repair plan.

## Apply workflow

1. Check for running Codex processes and disk space.
2. Generate staged merged files under `/tmp/codex-merged-stage-<stamp>/`.
3. Validate staged files:
   - every affected file parses as JSONL
   - no backup body record is missing after normalization
   - no Windows path roots remain in affected files
   - session header count did not increase compared with current
4. Copy every target file to a rollback tree before replacing:

   ```text
   ~/.codex-merge-rollback-<stamp>/...
   ```

5. Replace target files atomically with `os.replace`/same-filesystem temp files.
6. Verify after apply:

   ```bash
   python3 - <<'PY'
   import sqlite3
   from pathlib import Path
   for db in [Path.home()/'.codex/state_5.sqlite', Path.home()/'.codex/logs_2.sqlite']:
       con = sqlite3.connect(f'file:{db}?mode=ro', uri=True)
       print(db, con.execute('PRAGMA quick_check').fetchone()[0])
       con.close()
   PY
   ```

## Deletability rule

`~/.codex-merge-backup` is deletable only after:

- the backup has been archived or a rollback tree exists,
- all backup body events are represented in live or exported corpus after normalization,
- validation report shows zero missing backup-normalized body records,
- the user is happy with the result after a cooling-off period.

Until then, keep it. It is small compared with `.t3`, `.codex`, and `.hermes`, and can contain unique training traces.

## Pitfalls

- Filenames matching under `~/.codex/sessions` does not imply content containment.
- Many differences are only path style (`C:\\Users\\foxsc` vs `/home/semyon`), but some include appended calls/turns.
- Full `~/.codex/sessions` may have unrelated pre-existing parse-broken JSONL lines; do not blame the merge unless the affected-file validation fails.
- Avoid making negative durable claims like “Codex JSONLs are broken”; capture the parse/validate/rollback pattern instead.
