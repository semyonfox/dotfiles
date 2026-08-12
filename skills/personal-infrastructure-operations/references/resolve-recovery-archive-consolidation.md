# Resolve recovery archive: SHA-256 consolidation

Use for a **copied/recovery** DaVinci Resolve archive that contains multiple source namespaces (for example NAS, old Windows, recovered NVMe) and has Resolve auto-backup UUID trees. Do not use against a live Resolve Disk Database.

## Target layout

```text
<archive>/Resolve Project Backups/
  <project UUID>/
    Project.db.<timestamp>
    <timeline UUID>/
      Timeline.<timestamp>
```

The project UUID is the parent; a nested UUID identifies a timeline. `Project.db.<timestamp>` is a full local project database snapshot; `Timeline.<timestamp>` is a timeline backup and should be recovered through Resolve, not raw-merged with SQLite files.

## Safe sequence

1. **Find the actual archive host first.** If Semyon gives a PC path, SSH to `pc` and `stat` the exact path. Do not substitute a server/NAS directory with a similar name.
2. **Inventory all payloads read-only.** Select every regular file beneath each source's `Resolve Project Backups/`, including files suffixed `.dedupe-tmp`. For each record capture:
   - relative target path after `Resolve Project Backups/`
   - source path
   - byte size
   - SHA-256
3. **Detect collisions.** Group by target relative path. If a group contains more than one SHA-256, stop: it requires an explicit collision-naming policy, not an overwrite.
4. **Audit temporary dedupe files.** Before deleting them, prove every `.dedupe-tmp` hash has an ordinary-file equivalent. Preserve any exception as a normal canonical payload.
5. **Stage without deleting.** Create a new staging root on the same filesystem. For each target path, create one hardlink to a source representative (`os.link`) where supported; otherwise checksum-copy. Write a JSON manifest containing canonical path, SHA-256, bytes, and every original source path.
6. **Verify staging.** Re-hash every canonical output against the manifest. Require zero mismatches before touching source trees.
7. **Prune exact roots only.** Write a prune receipt, then remove only the enumerated former `Resolve Project Backups` roots. Remove each device/source directory only if it is now empty.
8. **Promote and verify again.** Move the staging backup tree to `<archive>/Resolve Project Backups/`, update absolute paths in the manifest/receipt, update the README, and re-hash all outputs post-promotion.

## Interpretation

A canonical tree with `N` files and `N` unique SHA-256 values has no remaining **byte-identical payload duplicates**. This does not prove every timestamped Resolve backup is creatively distinct: two backups may differ only in internal metadata yet look equivalent in Resolve. Do not delete those semantic candidates without Resolve-side comparison and an additional recovery backup.

## Preserve separately

Do not accidentally absorb `portable-files/` into the UUID tree. `.drp`, `.dra`, and `.drt` files are separately importable recovery material and need their own inventory/import validation.
