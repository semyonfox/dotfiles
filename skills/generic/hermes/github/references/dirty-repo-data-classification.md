# Dirty repo data classification

Use this when a dirty worktree contains databases, generated reports, env/config files, or personal experiment artifacts mixed with real source changes.

## Triage pattern

1. List tracked and untracked data-like files separately:
   - `git ls-files | grep -Ei '(sqlite|sqlite3|\.db|\.sqlcipher|\.enc|\.encrypted|\.env|\.csv|\.pdf|\.wav)'`
   - `git ls-files --others --exclude-standard | grep -Ei '(sqlite|sqlite3|\.db|\.sqlcipher|\.enc|\.encrypted|\.env|\.csv|\.pdf|\.wav)'`
2. For SQLite-looking files, inspect the first 16 bytes before assuming safety:
   - plaintext SQLite starts with `SQLite format 3\0`
   - SQLCipher/encrypted DBs should have a random-looking non-SQLite header
3. If the project has an encryption verifier/migration script, run that rather than opening or dumping tables. Verify only that the encrypted DB can be opened with the configured key; do not print rows or PII.
4. Check reachable Git history for prior plaintext blobs before saying the repo is clean:
   - enumerate `git rev-list --all -- path/to/db`
   - for each unique blob, inspect the first 16 bytes with `git cat-file -p <blob> | head -c 16` or equivalent
   - report `plain_blobs=0` or identify the contaminated blobs/refs if any plaintext SQLite headers appear
5. Treat missing local keys/credentials as an access limitation, not a failure of the repo. You can still report structural evidence: header bytes, tracked/untracked file list, and history scan.
6. Keep personal experiments out of the candidate PR even when adjacent tooling is useful. Delete or exclude pricing reports, raw course exports, generated dashboards, audio samples, local DB backups, `.env`, and cache artifacts unless the user explicitly asks to preserve them.

## Line-ending and IDE noise

When a dirty repo shows huge equal insertions/deletions, run a whitespace-aware comparison before classifying it as feature work:

```bash
git diff --ignore-space-at-eol --stat
```

If the meaningful diff disappears, recommend reverting or normalizing separately. Do not PR line-ending churn bundled with real feature work.

## Reporting shape

For each repo, separate:

- **KEEP / PR** — source, tests, docs that implement real behavior
- **KEEP LOCAL** — personal research, samples, private docs, one-off reports
- **DO NOT COMMIT** — secrets, env files, plaintext/private DBs, generated binaries, cache/IDE metadata
- **DISCARD** — accidental broken edits, line-ending churn, stale generated output
