# Windows device-dump to canonical-user merge review

Use when a Windows/PC home dump sits under a NAS `device_dumps` tree and Semyon is consolidating personal material into the canonical NAS user directory.

## Destination policy

Treat the canonical user tree (for example `/mnt/storage/users/semyon`) as the destination of record, and the device dump as an archive/recovery source. Never use an archive dump to overwrite canonical paths.

## Read-only review sequence

1. Inventory source and canonical top-level roots: regular-file counts, apparent bytes, and mtimes. Write the audit under the source dump, not the canonical tree.
2. Explicitly classify these as **archive-only/device-specific** unless Semyon names an exception:
   - `AppData`, Windows shell folders, Scoop, VirtualBox VMs;
   - toolchains/caches (`.pnpm-store`, `.rustup`, `.jdks`, `.dotnet`, package caches);
   - local application state, agent state, browser state, credentials, and device configuration;
   - Resolve cache/proxy/render/database state.
3. Explicitly leave all OneDrive roots and archival OneDrive copies untouched. `OneDrive`, a university/business OneDrive root, and `archives/onedrive` can be overlapping and semantically messy; do not infer a winner from timestamps or paths.
4. For named personal-content roots (normally `code`, `Downloads`, `Documents`, `Desktop`, media), compare each source root to its matching canonical root with:
   - an `rsync -anic --ignore-existing` dry run to find safely missing paths;
   - an `rsync -anic --existing` comparison for same-path content differences.
5. Group difference reports by project/top-level subdirectory. Dependency trees (`.venv`, `venv`, `node_modules`), `.git`, and IDE state often dominate apparent code differences. Do not mistake their count for missing source work.
6. Git directories within a dump may be broken worktree pointers. Do not trust `git remote` from an archived directory until `git -C <path> rev-parse --is-inside-work-tree` succeeds.

## Promotion rule

Only promote a category when it has a clear destination and no same-path file-content conflict. Use `rsync -a --ignore-existing`, exclude device/cache roots, produce an itemized manifest, then SHA-256 verify each newly promoted regular file against its source. Existing canonical content always wins.

A common safe Resolve exception is `Resolve Project Backups/`; preserve that separately from `CacheClip`, `ProxyMedia`, `Renders`, local disk databases, and generated galleries.

## Prune rule

Do not prune a Windows dump merely because a shallow inventory looks redundant. First promote/verify approved content and record what remains intentionally archive-only. OneDrive and AppData require separate approval if ever removed.
