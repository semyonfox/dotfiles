# Servarr manual import, container paths, and verified download-source pruning

Use for a pre-existing `/mnt/media/arrs/downloads` backlog that qBittorrent does not report as a completed job. Normal completed-download handling will not automatically discover this backlog; inventory and import it deliberately.

## Safe import flow

1. **Confirm container mount namespaces.** The host path `/mnt/media/arrs/downloads` is normally mounted into Arr containers as `/downloads`; do not pass host paths to an Arr API. Media roots likewise appear as container paths such as `/data/movies`, `/data/tvshows`, and `/data/music`.
2. **Use the manual-import scan read-only first.**
   - Radarr/Sonarr: `GET /api/v3/manualimport?folder=/downloads`
   - Lidarr: `GET /api/v1/manualimport?folder=/downloads/<album>&artistId=<existing-id>`
   Filter out any resource with `rejections`, and import only entries that have a concrete matched movie/episode/track.
3. **Submit imports through the Command API**, not `POST /manualimport` (that endpoint reprocesses import candidates):
   - Radarr/Sonarr: `POST /api/v3/command` with `name: "ManualImport"`, `importMode: "copy"`, and mapped `files`.
   - Lidarr: `POST /api/v1/command` with `name: "ManualImport"`, `importMode: "copy"`, `replaceExistingFiles: false`, and mapped track files.
   Explicit `copy` avoids moving downloads/seeding sources. Do not assume this becomes a hardlink across all NAS/container layouts.
4. **Poll the command resource until terminal status** and validate actual import history, not only a completed command. Sonarr/Lidarr can run serially and slowly when media probing is on NFS; do not launch another broad source scan concurrently.

### Required file mappings

- Radarr file: `path`, `movieId`, `quality`, `languages`, `releaseGroup`, `indexerFlags`
- Sonarr file: `path`, `folderName`, `seriesId`, `episodeIds`, `quality`, `languages`, `releaseGroup`, `indexerFlags`, `releaseType`
- Lidarr file: `path`, `artistId`, `albumId`, `albumReleaseId`, `trackIds`, `quality`, `indexerFlags`, `disableReleaseSwitching`

For Lidarr backlogs, inspect embedded audio tags (prefer `album_artist`, then `artist`) from one audio file per top-level album folder. Match normalized artist names *exactly* against existing Lidarr artists before calling an artist-scoped manual-import scan. Leave missing, ambiguous, or untagged artists alone; do not bulk-add/guess them.

## Conditional source cleanup after import

User approval to remove downloaded copies applies only to individually proven imported source files—not the entire Downloads tree.

1. Wait for every relevant Arr import command to complete.
2. Obtain each app's paged history. For the manual recovery run, select `downloadFolderImported` entries in the run window and normally require `data.downloadClient == null`, so active qBittorrent jobs are excluded.
3. Translate history paths from container to host namespace:
   - `/downloads/...` → `/mnt/media/arrs/downloads/...`
   - `/data/movies/...` → `/mnt/media/arrs/movies/...`
   - `/data/tvshows/...` → `/mnt/media/arrs/tvshows/...`
   - `/data/music/...` → `/mnt/media/arrs/music/albums/...`
4. For each exact source/destination pair: ensure both regular files exist, compare sizes, compute SHA-256 for both, then unlink only the source when hashes match. Record every result in a JSONL manifest outside Downloads. Leave sidecars, unmatched content, incomplete files, failures, and empty/non-empty folders alone unless separately approved.
5. Report logical Downloads reduction separately from NAS `df` capacity. Btrfs snapshots may retain extents, so physical free space may not move immediately. Inspect NAS-side Btrfs allocation/snapshot coverage read-only before claiming reclaimed physical capacity.

## Verification and reporting

- Report import history counts/titles and the command status.
- Report prune counts as `deleted_verified_identical_source`, `source_already_absent`, `destination_missing`, `size_mismatch`, `hash_mismatch`, and `error`.
- Never describe a completed API command as a successful import unless history/destination evidence confirms it.
