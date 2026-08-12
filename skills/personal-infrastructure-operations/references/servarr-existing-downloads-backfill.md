# Servarr backfill for pre-existing Downloads directories

Use this when `/mnt/media/arrs/downloads` already contains completed media that is **not** an active/recognised qBittorrent completed-download item. Normal Completed Download Handling will not retroactively discover that pile, even when qBittorrent is configured correctly.

## Safety model

- Inventory first; do not force rejected or unrecognised files.
- Use each app's `GET /manualimport?folder=/downloads` endpoint to discover candidates.
- Submit imports through `POST /api/<version>/command` with `name: "ManualImport"` — `POST /manualimport` is a reprocess endpoint in current Servarr APIs, not the import action.
- Always set `importMode: "copy"` for a shared download tree, and `replaceExistingFiles: false` for Lidarr. This preserves source files/seeding and avoids replacement surprises. It will normally hardlink when source and destination share the NAS filesystem, but do not promise space reclamation until sources are deliberately reviewed.
- Start only one deep import/scan job at a time on the NAS. Sonarr's media probing can process roughly one file per minute across NFS; a concurrent broad Lidarr scan can stall/time out and makes both jobs worse.

## Read-only discovery

1. Confirm the active app mounts. Typical mappings:
   - Radarr: `/downloads` -> NAS downloads and `/data/movies` -> library
   - Sonarr: `/downloads` -> NAS downloads and `/data/tvshows` -> library
   - Lidarr: `/downloads` -> NAS downloads and `/data/music` -> library
2. Check enabled download clients. A qBittorrent client in Radarr/Sonarr/Lidarr means **new qBittorrent-tracked completions** are automatic; it says nothing about historical files already on disk.
3. Call `GET /manualimport?folder=/downloads` for Radarr/Sonarr. Filter only resources with an empty `rejections` list and a resolved `movie` or `series` object.
4. For Lidarr, its generic scan may show unassociated audio with empty `tracks`. For a safe recovery pass, enumerate direct audio-bearing source folders, read one representative file's `album_artist` / `albumartist` / `artist` tag with quiet `ffprobe`, normalize conservatively (casefold, collapse whitespace, strip a trailing `feat.`/`ft.`), and exact-match it against current Lidarr artists. Do not rely on release-folder names alone.

## Import payloads

### Radarr

For each accepted discovery item, submit a command file with:

```json
{
  "path": "/downloads/example.mkv",
  "movieId": 123,
  "quality": { "...": "from discovery" },
  "languages": [{ "...": "from discovery" }],
  "releaseGroup": "from discovery",
  "indexerFlags": 0
}
```

Command envelope:

```json
{"name":"ManualImport","importMode":"copy","files":[...]}
```

### Sonarr

Use the accepted discovery objects and pass `seriesId` **from `series.id`** (not a missing top-level `seriesId`), `episodeIds` (the IDs under `episodes`), `folderName`, `quality`, `languages`, `releaseGroup`, `indexerFlags`, and `releaseType` in each file. The command envelope is the same `ManualImport`/`copy` shape. Do not submit a second manual-import batch while a previous `ManualImport` command is queued or running.

### Lidarr

For each exact-matched existing artist, call:

```text
GET /api/v1/manualimport?folder=<source-folder>&artistId=<id>
```

Import only items where all of the following hold:

- `rejections` is empty
- `tracks` is non-empty
- returned `artist.id` equals the artist ID supplied
- `album.id` and `albumReleaseId` are present

Build command files from `path`, `artistId`, `albumId`, `albumReleaseId`, `trackIds`, `quality`, `indexerFlags`, and `disableReleaseSwitching`. Use batches (for example 100 tracks), wait for each command to finish before starting the next, and preserve logs outside the media tree.

## Verification and reporting

- Poll `/command/<id>` until a terminal state; a `completed` command is the authoritative completion signal.
- Use app history with `eventType=downloadFolderImported` since the command start time to count actual imports while a long Sonarr/Lidarr command runs.
- Re-run broad manual-import discovery only after current long jobs finish; it is expensive over NFS and candidates may still be listed even after a copy import depending on the endpoint's existing-file filter.
- For an explicitly requested, time-bounded series-specific watcher, exclude qBittorrent's `incomplete` path; wait until the release appears in the completed download root, restrict discovery to the exact existing Sonarr series ID, and—when the release has `S01`/`S02` child folders—scan one still-incomplete season directory per command rather than the parent pack directory repeatedly. Submit only resolved/unrejected files with `importMode: "copy"` and `replaceExistingFiles: false`, emit only state changes, and never schedule a new batch while a `ManualImport` is active. This preserves active downloads, sources/seeding, and existing episode files while filling gaps.
- Report separately: imported, currently running, safely unmatched/untagged, corrupt/incomplete downloads, and sources deliberately retained.
