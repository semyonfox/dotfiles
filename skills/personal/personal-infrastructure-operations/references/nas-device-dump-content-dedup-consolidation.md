# NAS device-dump content dedupe and consolidation

Use when Semyon asks to audit, deduplicate, or consolidate archived PC/laptop/phone device dumps on the NAS, especially before deciding what deserves off-site backup.

## Scope and interaction

- A request may begin as research but become a direct-operation request. If Semyon subsequently says **do not delegate**, immediately stop delegating and work directly.
- Treat `dedup` as **storage deduplication that preserves every pathname**, unless he explicitly asks to delete/archive source copies. Do not use `fdupes -d` as the default.
- Do not bulk-promote files from a device dump into canonical folders without a source→destination manifest and collision/hash check. A dump can contain old, partial, or duplicated user state.

## Read-only inventory first

1. Identify the NAS-local Btrfs mount and inspect from the NAS host, not through an NFS client. Client `du` can stall or misrepresent exports/snapshots.
2. Measure apparent bytes, allocated bytes and file counts for candidate roots. Include real application data, but classify caches, toolchains, package stores, generated artifacts and live databases separately.
3. Map device-dump roots against canonical destinations, for example:
   - `Videos`, phone `DCIM`/`Movies` → canonical videos or an Immich import staging area
   - `Pictures` → canonical pictures / Immich import staging
   - documents → canonical documents
   - code/dotfiles → canonical project repo or a dated archived copy
   - game saves → canonical saves, never whole game installs
4. Avoid treating whole homes, `AppData`, `Downloads`, SDK/toolchain trees, `node_modules`, AI-agent caches, browser caches, VM images, or recycle bins as automatic remote-backup candidates.

## Safe dedupe method on Btrfs

### First pass: extent-level dedupe

`duperemove -r -d -A` can dedupe matching extents while keeping every path. `-A` opens files read-only. Run low priority with `ionice -c3 nice -n 19` and write a compact log, not a per-extent verbose log (verbose output can exceed a gigabyte for millions of files).

This is useful, but it is not a proof that every small file was deduped: default block behavior can skip tiny files.

### Thorough pass: file-content hashing

For an exhaustive pass, hash every regular file using SHA-256 and group on `(size, digest)`. For exact matches, use Btrfs `FICLONE` / reflink into the existing destination inode rather than deleting or replacing paths. Requirements:

- never follow symlinks;
- skip non-regular files;
- re-stat a file after hashing and skip it if it changed;
- preserve atime/mtime after `FICLONE`;
- record permission failures without treating them as data errors;
- use a persistent SQLite checkpoint on the NAS and a detached (`nohup` or user systemd) NAS-local process. A long SSH-piped process can disconnect even though the NAS is healthy.

A normal user may hit `EPERM` on archived files. Those content hashes are still valid; a privileged follow-up needs NAS-side sudo/root and must retain the same path-preserving reflink model.

## Accounting and reporting

- **Logical reflinked bytes are not necessarily newly freed filesystem bytes.** Earlier dedupe/reflink activity may already have shared extents.
- To report actual physical storage reclaimed, capture a Btrfs exclusive/shared allocation baseline *before* mutation and again after. `df` and ordinary `du` are not enough, and a post-run-only measurement cannot reconstruct exact reclaimed bytes.
- Report separately: files hashed, bytes hashed, exact duplicate files, files reflinked, already-shared inodes, logical bytes reflinked, unreadable/changed files, and reflink failures.
- Preserve a concise final JSON summary outside `/tmp`; raw logs should be compact or compressed.

## Consolidation after dedupe

Create a reviewable manifest before any move:

| source dump path | proposed canonical destination | hash/collision verdict | action |
|---|---|---|---|

Only then move or copy approved unique personal content. Keep one stable archival device-dump version until canonical destinations have passed restore/content verification. Never infer that dedupe means the old dump is safe to delete.
