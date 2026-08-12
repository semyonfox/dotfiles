# Codex runtime backup merge and path normalization

Use when Semyon explicitly approves merging a `.codex-merge-backup` or similar backup into live `.codex/sessions`, especially after first-pass comparison showed unique backup records.

## Default stance

Prefer offline corpus export with provenance. Only mutate live `.codex/sessions` after Semyon explicitly says to merge it in.

## Safe live-merge workflow

1. **Inspect first, read-only.** Compare backup/current by relative path, file hash, JSONL parseability, raw line hash, and normalized semantic keys. Matching filenames are not enough.
2. **Make rollback copies before apply.** Copy the exact live files/tree being changed to a timestamped rollback root such as `~/.codex-merge-rollback-YYYYMMDDTHHMMSSZ`.
3. **Stage all output.** Generate merged JSONL files in `/tmp` or another staging directory, not in place.
4. **Normalize paths before dedupe.** Canonicalize common variants to current Linux paths, e.g. `C:\Users\foxsc`, `C:/Users/foxsc`, `\\?\C:\Users\foxsc`, `/mnt/c/Users/foxsc` -> `/home/semyon`; normalize mixed slashes.
5. **Prefer current session headers.** Do not import backup `session_meta` headers into live files. Existing live files may already contain multiple headers; preserve existing headers, but do not introduce extra backup identities.
6. **Deduplicate exact normalized events.** Collapse byte/semantic duplicates after path normalization.
7. **Keep non-path conflicts as variants.** If the same event key differs beyond path spelling, keep both rather than silently losing appended tool output or work.
8. **Validate before replace.** Every staged JSONL must parse. Validate line counts, duplicate handling, and that every backup body record is represented after normalization.
9. **Atomically replace affected files only.** Replace just the files touched by the backup/current pairing, plus any approved copied-new files.
10. **Post-apply validation.** Re-scan affected live files for JSONL parse errors, backup coverage, remaining Windows path fragments, and SQLite health for `state_5.sqlite` / `logs_2.sqlite` read-only.

## Reporting

Report rollback path, apply/validation report paths, old/current/merged line counts, unique records added, duplicates collapsed, conflict variants kept, parse errors, and whether live/source stow-managed files match where relevant.

## Pitfalls

- Do not append old lines directly into current rollout files without staging; Codex rollouts are ordered event streams.
- Do not delete forensic backups until the live merge or offline corpus export is verified.
- Do not treat `state_5.sqlite` as a complete index; parse session JSONL directly and use DB rows as metadata.
- A file can already be multi-session or have duplicate `session_meta`; validate that the merge does not make it worse rather than assuming one header per file.
