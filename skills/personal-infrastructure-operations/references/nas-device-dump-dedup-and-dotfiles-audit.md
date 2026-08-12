# NAS device-dump deduplication and dotfiles-retention audit

Use when Semyon asks to deduplicate recovered PC/laptop/phone dumps, decide which old device data should be kept remotely, or compare dump dotfiles to the current Git repository.

## Safety and sequence

1. **Baseline before mutation.** On the NAS Btrfs host, capture filesystem capacity plus Btrfs per-path exclusive/shared accounting for every target root *before* deduplication. Ordinary `df` and GNU `du` cannot retrospectively prove physical space reclaimed by reflinks. Keep the raw output and timestamp.
2. **Scope only approved dump roots.** Typical paths include:
   - `/export/nas/users/semyon/device_dumps`
   - `/export/nas/users/semyon/.recycle/semyon/device_dumps`
   - `/export/nas/backups/laptop/linux_ingress`
   Do not sweep canonical user media or unrelated backup roots by default.
3. **Content hash before semantic consolidation.** Treat different path names, mtimes, or backup dates as non-evidence. Hash regular files, do not follow symlinks, and record read errors/changed files.
4. **Preserve all paths when storage-deduping.** Prefer Btrfs reflink/extent dedupe over `fdupes -d` deletion. It retains every recovery path and version while sharing blocks. Use low I/O priority.
5. **Use NAS-resident, resumable execution for multi-million-file trees.** A streamed SSH job can disconnect after hours. Persist a checkpoint database and a compact progress log on the NAS, launch via `nohup` or a suitable service, and poll status separately. Do not emit one verbose line per extent to a local log.
6. **Record reclaim attribution.** Store a `(canonical path, duplicate path, SHA-256, size, outcome)` ledger or at least per-root counters. Without it, later reporting can only state logical bytes reflinked, not exact reclaimed storage by source category.
7. **Permission failures are not content failures.** Archived Linux dumps may contain read-only/root-owned Git objects, plugin caches, or agent state. Hash them, report `Permission denied` reflink failures separately, and use NAS-side elevated execution only with user approval. Do not delete them as a workaround.
8. **Separate storage dedupe from archival decisions.** After reflinking, review device dumps into: canonical data to promote, one archival recovery copy, and derived/cache/toolchain material excluded from remote backup. Do not bulk-move before collision/content verification.

## Dotfiles: compare against current Git correctly

1. Do not use a dirty or stale local checkout as the baseline. Resolve the remote default branch and clone/fetch that exact current commit into a separate audit checkout.
2. Audit all `*dotfiles*` dump/backup trees plus explicit full-home config roots (`.config`, shell files, `.local/bin`, `.ssh`, host config backups) while avoiding symlink traversal.
3. Hash every regular candidate file and compare against the current Git content-hash set.
4. Report per-root counts/bytes split into:
   - exact Git matches — normally no independent retention value;
   - config/credential-shaped nonmatches — review and preserve carefully;
   - agent state / Git metadata — archive only if historical recovery is valuable;
   - cache/toolchain/dependency content — normally exclude from offsite backups.
5. Keep current Git plus one intentionally chosen historical configuration/archive copy. Do not treat repeated full-home snapshots as independent dotfile backups once their unique pieces are extracted.

## Verification/reporting

- Verify process completion and read the final machine-readable summary.
- Report separately: files hashed, exact duplicate groups/files, successfully reflinked files, logical bytes reflinked, already-shared inodes, failures by errno/category, and **measured pre/post exclusive allocation delta**.
- If the pre-mutation Btrfs baseline is absent, say plainly that physical reclaim cannot be reconstructed exactly; do not equate logical reflinked bytes with free-space gain.
- Keep raw manifests/reports under `/home/semyon/nas-offsite-audit/`; avoid giant verbose logs unless specifically needed for forensic evidence.
