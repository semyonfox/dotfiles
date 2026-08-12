# Application-managed project-library archives

For DaVinci Resolve-style Disk Database sources, treat each source tree as a recovery artifact. The database may span `Project.db`, user/project hierarchy, and auxiliary files, so a content hash of one `Project.db` is useful for migration intake but does not make raw folder merging safe.

## Safe handling

- Copy source trees non-destructively to a clearly named archive namespace.
- Use SHA-256 groups to identify exact duplicate project states and write a canonical-project intake manifest.
- Hardlink identical files only within a verified archival tree and filesystem. This reclaims blocks without losing path provenance.
- Retain different-content historical revisions unless an explicit retention rule says otherwise.
- Create/verify a separate recovery archive before deleting old device-dump or workstation locations.
- Import or restore into the live Network Project Library through the application UI/API, never by combining raw Disk Database directories.

## Important distinction

A live PostgreSQL Project Library and its scheduled logical backups are not source duplicates. Keep them out of raw-source deletion manifests.
