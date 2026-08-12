# Servarr manual ingest from a shared Downloads folder

Use when completed files already exist under `/mnt/media/arrs/downloads` but Radarr/Sonarr did not automatically import them. Treat this as a **copy-import**, not cleanup: preserve the source files and torrents/seeding state.

## Preflight (read-only)

1. Verify `/mnt/media` is mounted and the `radarr`, `sonarr`, `lidarr`, and `qbittorrent` containers are healthy.
2. Inspect container mounts. On this stack the relevant mappings are:
   - Radarr: `/mnt/media/arrs/movies -> /data/movies`; `/mnt/media/arrs/downloads -> /downloads`
   - Sonarr: `/mnt/media/arrs/tvshows -> /data/tvshows`; `/mnt/media/arrs/downloads -> /downloads`
   - Lidarr: `/mnt/media/arrs/music/albums -> /data/music`; `/mnt/media/arrs/downloads -> /downloads`
   - qBittorrent: `/mnt/media/arrs/downloads -> /data/downloads`
3. Obtain API keys locally from each app's `config.xml`; do not print them. Query `GET /api/v3/manualimport?folder=/downloads` (Lidarr normally uses `/api/v1`) and select only candidates with an empty `rejections` array and a resolved target (`movie`, `series`, or `artist/tracks`).
4. Do not force rejected/unmatched candidates. They can be already imported, ambiguous, unsupported files, or content that is not currently managed by that app.

## Important API distinction

`POST /api/v3/manualimport` is **not** the import endpoint; it only reprocesses selected candidate metadata. It returns 404 for the old direct-import assumption.

To perform the actual import, create a `ManualImport` command at `POST /api/v3/command` using `importMode: "copy"` explicitly. Do not depend on `copyUsingHardlinks`; manual import defaults may otherwise move files and break qBittorrent seeding.

### Radarr payload shape

Build `files` from accepted scan candidates:

```json
{
  "name": "ManualImport",
  "importMode": "copy",
  "files": [{
    "path": "/downloads/example.mkv",
    "movieId": 123,
    "quality": {},
    "languages": [],
    "releaseGroup": "",
    "indexerFlags": 0
  }]
}
```

### Sonarr payload shape

```json
{
  "name": "ManualImport",
  "importMode": "copy",
  "files": [{
    "path": "/downloads/example.mkv",
    "folderName": "release-folder",
    "seriesId": 123,
    "episodeIds": [456],
    "quality": {},
    "languages": [],
    "releaseGroup": "",
    "indexerFlags": 0,
    "releaseType": "seasonPack"
  }]
}
```

## Verification and operational caveat

- Poll `GET /api/v3/command/<id>` until terminal status. Verify imports via each app's history (`downloadFolderImported`) and media-file endpoints, not merely that a command was accepted.
- Sonarr can process large NAS-backed manual-import batches slowly because it analyzes each file. Do not submit a second import command or repeatedly rescan `/downloads` while its command is running; poll the existing command/history instead.
- A copy/hardlink import deliberately leaves originals in Downloads. It does **not** reclaim space. Perform a later, separately approved seeding/duplicate cleanup review before deleting anything.
- If Lidarr reports files with no artist/album/track resolution, do not bulk-import them. Add/map the intended artists and validate metadata first.
