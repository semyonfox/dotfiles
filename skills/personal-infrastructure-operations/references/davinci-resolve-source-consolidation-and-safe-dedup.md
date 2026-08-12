# DaVinci Resolve source consolidation and safe dedup

Use this for cross-device recovery of Resolve Disk Databases and portable exports (`.drp`, `.dra`, `.drt`, `.drb`) into a PostgreSQL-backed Network Project Library.

## Inventory the real source filesystems, not the archive

When Semyon asks what exists on devices, scan the source mounts explicitly and exclude staging/recovery/archive roots. Do not report results from the copied archive as source-device findings. If he names a PC-side archive, SSH to `pc` and locate that exact directory first: do not substitute a same-topic NAS/server migration tree. Report the resolved host and absolute path before describing its contents.

Typical roots:

```text
PC Linux:          /home/semyon
PC Windows NVMe:   /mnt/windows-drive
NAS Semyon:        /mnt/storage/users/semyon
NAS Adam:          /mnt/storage/users/adam  # only when requested
Server:            /home/semyon and /srv
```

Exclude archive/staging directory names such as `Resolve-Library-Archive`, `RECOVERY-ARCHIVE`, and `resolve-migration`, plus noisy caches and dependency trees. Bound deep scans with `timeout`; if a broad NAS crawl stalls, report it as incomplete and narrow the source roots rather than treating a timeout as “no files.”

Record each portable file’s path, extension, size, mtime, and SHA-256 before copying. Resolve portable formats are distinct from raw Disk Database folders and must be inventoried separately.

## Consolidate without destroying evidence

1. Copy every discovered source into a named namespace under one PC archive (for example `nas-device-dumps/`, `pc-windows-ntfs/`, `pc-linux-current/`, `portable-files/adam/`). Never overlay similarly named source directories.
2. Preserve raw `Resolve Project Library` directories as recovery sources. Do not filesystem-merge them and do not copy their internal database files into PostgreSQL.
3. For exact byte duplicates in the PC archive, create hardlinks only within that one filesystem. Keep the original paths; emit a JSON manifest with SHA-256, canonical path, all linked paths, and reclaimed bytes.
4. Before pruning originals, create one NAS recovery mirror with `rsync -aH`, then run a checksum dry-run (`rsync -aHnrc --delete`) and require no differences.
5. Only after that verification, delete precisely listed source paths. Write PC and NAS prune receipts. Never delete a source just because its name resembles another project.

`rsync -aH` matters: `-H` preserves the archive’s hardlink deduplication in the NAS recovery mirror.

## PostgreSQL Resolve Vault deduplication

A Resolve PostgreSQL library is a relational graph, not a table of interchangeable project files. Never delete, merge, or “move” project rows using SQL based solely on matching project names or a single blob hash.

Safe candidate discovery:

- Group non-autosave `SM_Project` rows by `ProjectName` to find same-name candidates.
- A same-name plus identical `md5(FieldsBlob)` group is only a stronger candidate, **not proof** that the entire project graph is identical.
- Projects reference timelines, media pools, compositions, galleries, thumbnails, and other records across many tables. Direct SQL deletion can leave broken relationships or discard versioned timeline content.

Canonicalization must happen through Resolve: open/compare candidates, select the canonical project based on actual timelines/media/project state, then organize or delete rejected copies in Resolve’s Project Manager. Keep the source archive until those imports are validated.

### Read-only semantic duplicate fingerprinting

When a library shows repeated folder/project names such as `Folder (Copy) (Copy)`, direct project-blob hashes will normally differ because Resolve assigns object IDs and updates metadata. Before manual cleanup, build a read-only **content signature** for each candidate from:

- the sorted linked-timeline structure: name, type, create time, and modification time, joined through `SM_Project_Sm2Timeline` (`DbOwner` is the project and `DbAssociate` is the timeline);
- the media-pool contents: media-item name plus hashes of `VideoMetadata` and `MediaMetadata`, joined `SM_Project -> Sm2MediaPool -> Sm2MpFolder -> Sm2MpMedia`.

Matching timeline count/signature **and** media count/signature across a copy family is strong evidence of the same usable project content even when `SM_Project.FieldsBlob` differs. It is not a licence for SQL deletion and cannot prove every Resolve graph object (grades, Fusion compositions, galleries, project settings) is equivalent. Flag every family with a differing signature for Resolve-side comparison; retain the least-`(Copy)` clean-name version provisionally and export it to `.drp` before deleting copies. Generate a TSV plan with `KEEP` and `DELETE_IN_RESOLVE` rows, then remove projects in Resolve Project Manager and delete folders only after they are empty. Re-query the live library immediately before a final deletion recommendation: Resolve UI actions can change the library mid-audit, invalidating a previously generated plan.

## Portable exports versus Disk Database sources

Classify copied recovery material before explaining restore options:

- A full `Resolve Projects/Users/<user>/User.db` plus `Projects/<project>/Project.db` tree is a **local Disk Database**. Verify every SQLite file with read-only `PRAGMA integrity_check`; hash it to identify archive-copy duplicates. Keep the entire tree intact, register it as a separate local Disk Database in Resolve, then export/import selected projects through Resolve. Never raw-copy its SQLite files into PostgreSQL.
- `.drp` is an individual project export: validate ZIP-format files with `unzip -t`; non-ZIP/legacy-looking `.drp` files still need a disposable Resolve import to prove usability. Import into a temporary `Recovery Imports` folder/library first, not over an existing project.
- `.drt` is a timeline export, not a whole project. Import it only after opening or creating a destination project. Hash duplicate `.drt` files and retain one canonical copy.

A copied PC archive can contain portable `.drp`/`.drt` files but no Disk Database at all; state that distinction plainly rather than promising a database restore.

**Destructive-recommendation guard:** a plan is a point-in-time artifact. Immediately before telling the user to blanket-delete folders, re-run the live inventory and the candidate plan, compare its project/folder count to the prior report, and explicitly detect folders/projects that vanished or changed during the audit. If state changed, discard the old plan and report the current exact scope. Be direct about the conclusion, but never say “lose nothing” or claim absolute identity from SQL fingerprints alone; state the measured guarantee precisely (for example, “no copied candidate has a timeline/media key absent from the clean canonical project”) and require one fresh backup before the user deletes the scoped set.

## Communication pitfall

If the user says “actual devices,” answer only with source-device filesystem findings. Clearly distinguish source-device scans, the PC migration archive, and the NAS recovery mirror.