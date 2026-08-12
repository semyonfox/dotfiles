# Immich staged imports and verified legacy-source pruning

Use when importing media staged outside Immich and Semyon authorises removal of redundant source/archive copies.

## Safe sequence

1. Inventory each staged root: paths, file count, apparent size, media extensions. Keep separate source batches separate.
2. Upload through the Immich client/API only; never copy files into `UPLOAD_LOCATION` manually. Do **not** use the client `--delete` flags during the initial upload.
3. Run a recursive `immich upload --dry-run` against each source batch after upload. Require `0 new` assets before removing the batch.
   - CLI `Received` can be lower than the raw path count because it collapses byte-identical local files and ignores non-assets. Verify each source subdirectory if aggregate output is unclear.
4. For a legacy managed-data archive, dry-run its canonical `library` assets. If it has new assets, upload those first; re-run dry-run and require all recognised assets to be duplicates before pruning the archive. Do not upload `encoded-video` derivatives or database dumps.
5. Before deletion, record exact scope, regular-file count, apparent bytes, upload/dry-run result, and UTC timestamp in a receipt outside the deleted directory. Delete only the named roots; verify each path is absent afterward.
6. Retain current native PostgreSQL dumps until an offsite `restic check` and disposable restore prove recovery. Keep small recovery evidence and device-dump archives unless their canonical coverage is separately verified.

## Snapshot nuance

A Btrfs snapshot can retain deleted extents, so `df` may not fall immediately after an otherwise successful prune. This is expected rollback protection, not evidence that deletion failed. Do not prune snapshots merely to force a space-number change without separately reviewing retention and recovery impact.
