# Selective offsite and first-snapshot evidence

## Data architecture

Authoritative preservation guidance supports separating active/canonical work, curated archives, app exports, and backup copies. Select data for long-term value before organising/copying it; preserve raw device captures separately from derived/working copies; retain an inventory and integrity evidence outside the content.

- UK National Archives, digital preservation stages and consistent management: https://www.nationalarchives.gov.uk/archives-sector/advice-and-guidance/managing-your-collection/preserving-digital-collections/
- Library of Congress, personal digital records: https://www.digitalpreservation.gov/personalarchiving/records.html
- NDSA Levels of Digital Preservation, inventory/integrity/copy guidance: https://osf.io/u8m3w/

Practical interpretation:

```text
live/canonical → selected versioned offsite backup
app exports     → selected versioned offsite backup
archive source  → preserve original + work on a separate derived copy
caches/outputs  → exclude unless explicitly needed
```

## Restic

- Backups are snapshots; unchanged data is deduplicated. `--parent` controls file change detection and default selection groups by host and paths.
- `forget` removes snapshots; `prune` removes data no longer referenced. Preview policy first and check after pruning.
- `check` validates repository structure. `check --read-data` verifies pack contents and can be rotated with `--read-data-subset`.

Sources:

- https://restic.readthedocs.io/en/stable/040_backup.html
- https://restic.readthedocs.io/en/stable/045_working_with_repos.html
- https://restic.readthedocs.io/en/stable/060_forget.html

### Initial failure recovery pattern

1. An upload cap/billing failure can leave unreferenced repository packs and no usable snapshot.
2. Fix provider acceptance, then retry. Do not call the repository protected until a complete snapshot exists.
3. A restic exit code `3` can still commit a partial snapshot after an unreadable source file. Fix the exact permission/ACL anomaly, take a follow-up snapshot, and restore-test it.
4. Use `prune --dry-run` only after a known-good snapshot. Prune verified unreferenced packs, then run `check` again.
5. Timestamped export roots prevent default parent matching. Use a stable input path or explicit parent selection, and remember that large NFS trees still need metadata traversal.

## Resolve

Blackmagic distinguishes:

- Project Library backup — library state;
- logical database export — database recovery;
- `.drp` — project data (standard export omits stills/LUTs);
- `.dra` — project plus referenced media, optional cache/optimized media.

Before restructuring source media, generate and validate a suitable Resolve-native archive/export. Treat render cache, optimized media, proxy media, and final renders as separate categories rather than applying blanket deletion.

Source: https://documents.blackmagicdesign.com/UserManuals/DaVinci_Resolve_21_Reference_Manual.pdf
