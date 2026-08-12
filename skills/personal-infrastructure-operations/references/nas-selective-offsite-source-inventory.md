# NAS selective offsite source inventory

Use this before choosing a cloud-backup capacity or writing an allow-list. The aim is to measure canonical, irreplaceable recovery sources on the NAS itself without treating a whole NFS export, media library, or historical dump pile as a backup set.

## Guardrails

- Read-only unless the user later approves a clearly scoped consolidation/deletion plan.
- For deep inventory work, prefer one direct operator-controlled scan rather than delegation if Semyon requests it; do not run multiple deep `du`/hash traversals concurrently against the NAS.
- Run traversal on the NAS's real filesystem path over SSH, not only through `/mnt/media` NFS. Record the real export path and mount identity first.
- Write reports on the orchestration host, not the NAS. Avoid printing secret contents or full sensitive filename lists in chat.
- Use `du -sxB1 --apparent-size` and `du -sxB1` for logical versus allocated size. Capture file counts and explicit errors. Do not silently treat an inaccessible path as empty.
- Do not follow symlinks or cross unexpected mounts (`-xdev`). Use long, bounded timeouts for individual roots.

## Workflow

1. Discover the NAS-side export and filesystem with `findmnt`, `df -hT`, and shallow directory inventory. NFS client `du` can time out or undercount.
2. Measure broad candidates only to establish scope: Immich canonical paths, user roots, laptop/device backups, service configuration, Vaultwarden, application exports, archives, game/service state; separately measure exclusions such as Arr media, caches, Immich derivatives/imports, live databases, snapshots, trash, and temp.
3. Break down every giant candidate (`users/<user>`, laptop backups, device dumps) one level at a time before adding it to a remote allow-list.
4. Treat device dumps as preservation data, not automatically backup-worthy canonical data. Inventory each device/version root, dated snapshots, recycle copies, staging copies, ingress directories, and newest file timestamp.
5. Discover exact duplicates only after the size scan completes. NAS-local `fdupes` can identify byte-identical files without mutation. Also measure hardlinked files: their summed logical size is not reclaimable/transferable as independent physical data.
6. Classify paths into **MUST**, **SHOULD**, **OPTIONAL**, **EXCLUDE**, and **NEEDS RESTORE TEST**. Examples:
   - MUST: canonical photo/video originals, unique documents/code, Vaultwarden state, recovery secrets/configuration, validated application exports.
   - EXCLUDE by default: commodity media, package caches, build outputs, generated Immich thumbnails/transcodes, raw live PostgreSQL directories, temporary directories, local snapshots, recycle bins.
   - NEEDS RESTORE TEST: historical laptop/device dumps, app-state trees, old database copies, deduplicated archives.
7. Produce a source manifest with path, apparent/allocated bytes, file count, status, ownership/recovery rationale, overlap risk, and an allow-list total that avoids nested-path double counting. Keep exact duplicate reports separate from a deletion proposal.

## Timing and operational notes

- Serialize deep scans: size breakdown first, then duplicate hashing. Concurrent traversal and hashing can swamp a NAS and make both results less trustworthy.
- A completed background command may produce shell-profile noise. Verify the actual local output artifact and its terminal completion marker rather than interpreting startup noise as the scan result.
- A raw live database directory is not an application-consistent backup; generate supported exports/snapshots before including it in an offsite job.

## Follow-up after inventory

Use the measured allow-list, not total NAS filesystem usage, for provider sizing and seed-time estimates. Never delete or consolidate duplicate device dumps based only on a duplicate report: first choose canonical copies and preserve a manifest, then obtain explicit approval for exact mutation scope.
