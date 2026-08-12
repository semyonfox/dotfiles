# DaVinci Resolve PostgreSQL library: read-only duplicate audit

Use before any Resolve Project Manager cleanup when a Network Project Library has repeated `(Copy)` folders/projects.

## Read-only remote procedure

1. Confirm the exact `resolve-postgres` container and enumerate non-template databases. Do not expose credentials or mutate data.
2. In the Resolve library, inventory:
   - `SM_Project` count and `IsAutoSave` count;
   - `SM_ProjectFolder` count;
   - `Sm2Timeline`, `Sm2MediaPool`, `Sm2MpMedia`, and `SM_Clip` counts;
   - `pg_database_size`.
3. Reconstruct the folder hierarchy from `SM_ProjectFolder.ParentFolder`. Do **not** infer nesting from names: repeated names such as `Gaming (Copy) (Copy)` can be root-level siblings.
4. Associate projects to folders through `SM_Project.Folder` and group candidates by a **display-only normalisation** that removes repeated ` (Copy)` suffixes from folder and project names. Keep the original names/UUIDs in any report.
5. Resolve timeline ownership through `SM_Project_Sm2Timeline`, where:
   - `DbOwner` matches `SM_Project.SM_Project_id`;
   - `DbAssociate` matches `Sm2Timeline.Sm2Timeline_id`.
   A direct `Sm2Timeline.SM_Project_id = SM_Project.SM_Project_id` join can return zero even in a library with valid timelines.
6. For every candidate family, compare version count, timeline count, latest timeline modification time, project `LastModTimeInSecs`, and (only as a weak signal) `md5(FieldsBlob)`.

## Interpretation and safety

- Copy-generation creation times clustered within minutes strongly indicate an accidental repeated copy/import operation, but they do **not** prove the newest project is canonical.
- Different `FieldsBlob` hashes do not establish meaningful content divergence; Resolve copies can change graph metadata/IDs.
- Equal timeline counts are useful evidence, but not proof that projects are interchangeable. Open and compare any material project in Resolve before deletion.
- A candidate with fewer timelines is a priority comparison case; retain the richer candidates until Resolve-side validation.
- Never remove/merge Resolve projects or folders with SQL. Use Resolve Project Manager after a fresh logical backup and keep the archive/backup until cleanup is verified.

## Report shape

Lead with: service health, library/database name and size, totals, whether folders are actual children or root siblings, number of duplicate families/entries, exceptions requiring manual comparison, and the estimated cleanup count. State explicitly that no mutation occurred.
