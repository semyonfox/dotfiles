# OBS, DaVinci, and cross-device footage workflow

Use for Semyon's recording/editing archive audits, OBS capture configuration, remux cleanup, or locating media across PC, NAS, and server mounts.

## OBS capture format

- Prefer **Hybrid MP4** in OBS 30.2+ for DaVinci Resolve workflows. It records in crash-resilient fragments and soft-remuxes into a conventional, editor-friendly MP4 on normal stop.
- Do **not** confuse it with plain `fragmented_mp4`: that stays fragmented and is less pleasant to seek/edit, particularly over NFS.
- Check both `[AdvOut] RecFormat2` and `[SimpleOutput] RecFormat2` in `~/.config/obs-studio/basic/profiles/<profile>/basic.ini`; output-mode switches otherwise can resurrect a stale format.
- Source Record filters maintain their own `rec_format` in the scene-collection JSON; audit them too.
- DaVinci-compatible Hybrid MP4 can keep multiple audio tracks. Bind OBS's `Add chapter marker` hotkey if requested; chapters are not recoverable after a crash because they are written only when finalizing.

## Remux cleanup: verify, then remove

Old recordings may contain both `.mkv` and `.mp4` versions. Do not delete based on names/extensions alone.

1. Pair files by identical stem in the same folder.
2. Probe both files for duration, stream count, codecs, dimensions, and audio-track layout.
3. Verify encoded stream identity with FFmpeg stream hashes, for example:
   ```bash
   ffmpeg -v error -i INPUT -map 0 -c copy -f streamhash -hash sha256 -
   ```
4. If every stream hash matches and both files are readable, retain MP4 for Resolve and remove MKV. Record an on-storage JSON manifest with paths, byte counts, retained counterpart, and reason.
5. If the MP4 fails to parse (often missing `moov` atom), preserve the valid MKV and remove only the broken MP4 after confirming the MKV is readable.
6. Verify retained paths after deletion. Never delete unmatched or partially verified pairs.

## Proxy editing with constrained PC storage

When original footage cannot remain on the workstation:

1. Ingest/record locally, then create proxies and keep Resolve cache, optimized media, and proxy files on the workstation NVMe.
2. Archive the camera/OBS originals on the NAS and relink the Resolve project to a stable NAS media path.
3. Edit in proxy mode locally. For final render, switch to camera originals and render directly from the NAS; do **not** copy the entire original archive back to the PC solely for export.
4. For active editing, use a high-throughput NFS/SMB mount over wired Ethernet. An SFTP/GVFS mount is acceptable for browsing or occasional transfer but is not the preferred path for sustained media I/O.
5. A dedicated direct Ethernet link should use a separate static subnet with no default gateway (for example a /30 link) so ordinary LAN/internet routes stay unchanged. Verify physical link state and throughput before relinking a live project.

Keep Resolve project databases separate from media storage: the database stays local or uses proper PostgreSQL; the media can reside on NAS storage.

## Cross-device audit model

Distinguish physical stores from mounts and from application databases:

- A server's NFS mount of a NAS is the **same data**, not a second archive.
- PC local storage is the active recording/editing workspace; NAS is normally the archive.
- The DaVinci Resolve Project Library is a small database distinct from raw media. Locate and report it separately; do not treat it as disposable cache.
- Legacy Windows editing folders may duplicate NAS assets. Inventory them as separate copies but do not consolidate/move without explicit approval.

For an inventory, report per root: media-file count, total size, major top-level directories, newest files, and distinct Resolve project-library/support locations. Start read-only and name absolute paths.

## Semyon's known layout (verify live; do not assume)

- PC OBS config: `~/.config/obs-studio/`
- PC active recordings: `~/Videos/OBS/`
- Linux Resolve project database: `~/.local/share/DaVinciResolve/Resolve Project Library/`
- NAS user archive export: `/mnt/media/users/semyon/` from the server; NAS-side canonical location is typically under `/mnt/storage/users/semyon/`.
