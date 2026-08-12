# Resolve font audit and NAS relink recovery

Use when a migrated Resolve Network Project Library opens with missing-font errors and offline media on Semyon's CachyOS PC.

## Font audit

1. Keep Resolve closed while installing fonts; inspect its rolling/archive logs first:
   ```bash
   grep -Rai 'Could not find font:' ~/.local/share/DaVinciResolve/logs
   ```
   The error is more reliable than attempting to decode every Fusion composition blob in a project database.
2. Correlate a warning with its project by looking at nearby `Loading project (...)` lines in the same Resolve debug log.
3. Verify an exact family/style with `fc-match 'Family:style=Style'`, not merely that some fallback font resolves.
4. Install free faces from authoritative upstream sources. For proprietary Windows faces, if the PC's own mounted Windows installation contains the exact licensed font, copy it into a dedicated system font directory with root permission and rebuild the cache.
5. Put recovery-installed fonts in `/usr/local/share/fonts/resolve-project-audit/`, run `fc-cache -f`, verify with `fc-match`, and restart Resolve only after verification. Do not launch Resolve merely to test unless asked.

## NAS relink discovery

1. Do a read-only scan of the live Resolve PostgreSQL library before changing links. Legacy source paths can be serialised inside `BtVideoInfo.Clip` and `BtAudioInfo.Clip` bytea fields, not only in normal path tables.
2. Treat serialized Windows `N:\users\semyon\...` references as NAS candidates. On the server, map them to `/mnt/media/users/semyon/...`; inventory those real NAS roots directly and exclude migration/recovery archives from the claim that a source still exists.
3. Check PC Linux, the mounted Windows volume, server-local roots, and NAS roots separately. Do not claim a copied Resolve archive is a recoverable media source.
4. Before relinking, ensure the PC has a stable high-throughput NAS mount. Prefer an NFS mount such as:
   ```text
   10.0.0.6:/nas -> /mnt/nas-media
   ```
   Verify the mount and representative referenced files on the PC. Do not use SSHFS/GVFS for active Resolve media.
5. Change links only through Resolve's **Change Source Folder** / relink UI. Never rewrite Resolve PostgreSQL rows or serialized media blobs. For the common legacy mapping, map old `N:\users\semyon\<root>` to `/mnt/nas-media/users/semyon/<root>` one root at a time, save, then open/verify representative timelines before bulk operations.
6. A persistent mount changes workstation configuration. If the user asked only for a quick existence check, stop after reporting the exact mapping and obtain approval before modifying fstab/systemd or launching Resolve's GUI.
