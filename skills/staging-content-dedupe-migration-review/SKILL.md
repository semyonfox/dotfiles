---
name: staging-content-dedupe-migration-review
description: "Use when deduplicate a staging/import tree by file contents, remove staging copies already present in canonical state, then produce a dry-run migration plan without modifying live files."
version: 1.0.0
created_by: agent

metadata:
  harness: [hermes]
---

# Staging Content Dedupe and Migration Review

Use when Semyon has a recovered, imported, device-dump, AI-state, or migration staging directory and wants his standard two-pass content dedupe followed by a reviewable dry-run migration analysis.

For application-managed project libraries and databases, see `references/application-database-archives.md`.

## Contract

1. Deduplicate regular files **inside the approved staging root** by `(size, SHA-256)`, regardless of filename.
2. Keep one deterministic copy per content group and delete the other staging copies.
3. Hash the relevant canonical/live roots read-only.
4. Delete any remaining staging regular file whose content already exists anywhere in the relevant canonical state, even under a different filename.
5. Keep all unique staging extras.
6. Produce a dry-run migration report. Do not modify canonical/live files until Semyon reviews and approves the proposed merge.
7. After a later approved merge, delete staging copies only after destination verification. Delete the staging root only when no unreviewed extras remain.

## Safety rules

- Inventory and record exact staging and canonical roots before hashing.
- When the requested outcome is “one copy” but source-path provenance must remain usable, prefer **hardlink deduplication** within one filesystem over deleting duplicate paths. Verify the replacement inode matches the chosen canonical inode and write a hash-to-path manifest.
- If the user asks to delete source copies across devices, first build and checksum-verify every requested recovery copy. Never start destructive pruning while the sole recovery transfer is incomplete.
- Treat a live service database and its scheduled backups as a separate destination/backup domain, not as disposable duplicate source data.
- For application-managed Disk Database/project-library folders, do not filesystem-merge raw database trees. Preserve sources and use the application’s supported import/restore workflow into the live database.
- Never follow symlinks. Report them for manual review.
- Never delete from canonical/live roots during dedupe.
- Only delete regular files inside the explicitly approved staging root.
- Save manifests outside the staging root so dedupe cannot remove its own evidence.
- Record read/hash/delete errors and stop before migration if errors are non-zero.
- Treat SQLite databases, WAL/SHM files, Git internals, active worktrees, and different-content same-path files as non-trivial.
- Do not overwrite live databases or concatenate JSONL/session files blindly.
- Use SHA-256 plus size; filenames and mtimes are supporting evidence only.

## Cross-device retention workflow

Use this when the user requests a single working archive plus one off-device recovery copy and authorizes removal of duplicate source locations.

1. Build the working archive with source namespaces intact; do not flatten application databases.
2. Hash every regular file and create a persistent manifest of `(size, SHA-256, canonical path, identical paths)`.
3. Collapse byte-identical files in the working archive to hardlinks where they are on the same filesystem. This preserves source paths but uses one physical allocation.
4. Create the requested recovery archive on the separate device using metadata- and hardlink-preserving copy options where available.
5. Verify recovery with a checksum dry-run (`rsync -nrc` or equivalent) and record zero differences.
6. Write an explicit pruning manifest listing every source root proposed for deletion, excluding live destination databases and ongoing backup targets.
7. Only then delete the approved duplicate roots. Verify the working and recovery manifests again after pruning.
8. Different-content historical database revisions are not “duplicates”; retain them unless the user explicitly chooses a version-pruning policy.

## Pass 1: dedupe staging internally

1. Capture before file count, logical bytes, `du`, and free space.
2. Recursively hash regular files without following symlinks.
3. Group by `(size, sha256)`.
4. Keep a deterministic winner, preferably shortest relative path then lexicographic path.
5. Delete other copies only from staging.
6. Record each deleted path, kept path, size, and hash.
7. Rescan and verify no duplicate content groups remain.

## Pass 2: dedupe staging against canonical state

1. Map each staged top-level namespace to its canonical root, for example:
   - `.t3` → `~/.t3`
   - `.codex` → `~/.codex`
   - `.claude` → `~/.claude`
   - `.gemini` → `~/.gemini`
   - `.cursor` → `~/.cursor`
   - `.copilot` → `~/.copilot`
   - `.config` → `~/.config`
2. Hash canonical regular files read-only into a global content index.
3. If staged content exists anywhere canonical, delete only the staging copy.
4. Record the staging path and at least one matching canonical path.
5. Rescan staging and record remaining unique content.

## Dry-run migration classification

Classify every remaining staging item:

- `drop_in`: target path does not exist; candidate for automatic copy after approval.
- `path_collision_different_content`: target exists with different content; preserve both or perform a semantic merge.
- `type_conflict`: file/dir/symlink types disagree; manual review.
- `symlink_manual_review`: inspect target; never auto-follow.
- `identical_path_content`: unexpected after pass 2; investigate.

Also classify content:

- SQLite/database
- session/history JSONL
- config or structured text
- logs/traces
- cache/vendor/node_modules/plugin checkout
- Git internals
- binary

Default migration recommendations:

- Auto-copy only useful, non-cache `drop_in` files after approval.
- Preserve different-content session/history files with a source suffix rather than overwriting.
- Skip rebuildable caches, logs, vendor trees, and plugin checkouts unless archive value is requested.
- Leave general `.config` collisions for manual review.
- Remove a staged file after an approved copy only after count/size/hash verification.

## SQLite/T3 handling

For `.t3/userdata/state.sqlite` or similar state databases:

1. Open both staging and live DBs read-only first.
2. Run `PRAGMA integrity_check` and inspect `foreign_key_check` where safe.
3. Compare schema SQL, tables, columns, primary keys, and row counts.
4. Never merge or copy WAL/SHM files.
5. If schemas are compatible, perform any future merge only on copies in a disposable work directory using primary-key-aware operations such as `INSERT OR IGNORE`.
6. Normalize obsolete Windows paths where required.
7. Show row-level before/after counts and integrity results before replacing live state.
8. Back up live state immediately before any later approved replacement.

## Required artifacts

Create a timestamped manifest directory outside staging containing:

```text
summary.json
REPORT.md
all_staging_hashes_before.csv
internal_duplicate_groups.json
internal_duplicates_deleted.csv
live_duplicates_deleted.csv
migration_dry_run.csv
errors.json
```

For databases also create a read-only schema/row-count analysis JSON and a human migration review.

The summary must include:

- before/after file counts and bytes
- internal duplicate groups/files/bytes removed
- canonical duplicate files/bytes removed from staging
- remaining migration counts by status and namespace
- symlink and error counts
- explicit safety booleans stating canonical state was not modified and migration was not applied

## Verification and reporting

Before reporting success:

1. Confirm all deletions were inside staging.
2. Confirm canonical roots were unchanged.
3. Confirm no hash/read/delete errors.
4. Verify staging's remaining duplicate-content count is zero.
5. Report manifest and migration-review paths.
6. Summarize easy drop-ins, collisions, databases, cache/log bulk, and the recommended approval batches.
7. Stop after the report. Wait for Semyon's explicit merge approval before changing live files.
