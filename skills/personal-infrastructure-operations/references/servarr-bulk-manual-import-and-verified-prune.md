# Servarr bulk manual import and verified source pruning

Use when completed media already exists under a NAS download directory but was not (or is no longer) represented as an active download-client job. Native completed-download handling only imports downloads the client reports; it does not reliably discover an arbitrary historical folder dump.

## Guardrails

- Inventory first; do not treat every file under Downloads as safe to import or delete.
- Keep one high-I/O import workflow active at a time on the NFS-backed NAS. Do not run Lidarr discovery concurrently with a large Sonarr import.
- Use `importMode: "copy"` and `replaceExistingFiles: false` for recovery/manual imports. This preserves sources while verification happens.
- **Do not assume copy mode became a hardlink.** On NFS, container mounts, or across filesystems it may produce a second physical copy. Check representative inode/link-counts and verify every deletion candidate by size plus SHA-256.
- Delete only individual source files whose destination is confirmed by the app’s import history. Leave incomplete, unmatched, non-audio/video extras, failed imports, and empty/non-empty source folders alone unless the user explicitly expands scope.

## 1. Verify mounts, services, and normal automation

1. Confirm `/mnt/media` is mounted and has enough free space.
2. Confirm `radarr`, `sonarr`, `lidarr`, and the download client are running.
3. Query each Arr app’s enabled download clients. If qBittorrent (or equivalent) is connected, future client-tracked completed downloads are already eligible for automatic import.
4. Explain that a legacy Downloads dump needs manual recovery; do not promise folder-watch automation where none exists.

The relevant mounts are commonly host `/mnt/media/arrs/downloads` and container `/downloads`; library paths may be host `/mnt/media/arrs/{movies,tvshows,music/albums}` and container `/data/{movies,tvshows,music}`.

## 2. Read-only candidate discovery

- Radarr/Sonarr: `GET /api/v3/manualimport?folder=/downloads`, then retain only candidates with no `rejections` and a resolved movie/series plus episodes as appropriate.
- Lidarr: `GET /api/v1/manualimport?folder=/downloads` alone identifies files but does not resolve them. For a known existing artist use `artistId` and a **container-visible** folder path:

```text
GET /api/v1/manualimport?folder=/downloads/<album-folder>&artistId=<id>
```

Do not accidentally pass the host NFS path (`/mnt/media/...`) to an app API. It may return an empty candidate list without an obvious error.

For large music recovery sets:

1. Read one audio file per top-level album folder with `ffprobe` metadata.
2. Normalize `album_artist` / `albumartist` / `artist` conservatively (casefold, whitespace; do not guess ambiguous aliases).
3. Match only one-to-one exact names against existing Lidarr artists.
4. Query Lidarr manual import per matched album folder and retain only files with no rejection, a returned matching `artist.id`, a resolved album/release, and at least one resolved track.
5. Leave no-tag, artist-mismatch, ambiguous, or untracked items for a separate metadata repair pass.

## 3. Submit actual imports through command APIs

`POST /manualimport` is reprocessing/update behavior in current Arr APIs; it is **not** the import operation. Submit `ManualImport` commands to the command endpoint instead.

### Radarr

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

### Sonarr

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

### Lidarr

```json
{
  "name": "ManualImport",
  "importMode": "copy",
  "replaceExistingFiles": false,
  "files": [{
    "path": "/downloads/artist-album/01-track.flac",
    "artistId": 123,
    "albumId": 456,
    "albumReleaseId": 789,
    "trackIds": [101112],
    "quality": {},
    "indexerFlags": 0,
    "disableReleaseSwitching": false
  }]
}
```

For large Lidarr sets, submit bounded batches (for example 100 tracks), poll each command to a terminal successful status, then submit the next. Persist a progress log with candidate count, batch IDs, command status, and failure details. Report actual completed-history counts, not merely submitted command counts.

## 4. Verification and deletion after explicit approval

Before removing any Download source:

1. Wait for all relevant Arr commands to reach `completed`.
2. Query paginated app history for this exact run window. Lidarr records are `trackFileImported`; its history `data` includes `droppedPath` and `importedPath`.
3. Translate app-container paths back to host paths (`/downloads/...` → `/mnt/media/arrs/downloads/...`; `/data/music/...` → `/mnt/media/arrs/music/albums/...`).
4. Build a source→destination manifest outside the deletion target.
5. For each pair: require both regular files, same byte size, then compare SHA-256. Only delete the exact source file after equality succeeds.
6. Record result per file (`deleted_verified_identical_source`, `destination_missing`, `size_mismatch`, `hash_mismatch`, error). Do not recursively remove source directories; they can contain cover art, cues, logs, or unmatched tracks.
7. Summarize removed/skipped/error counts and the manifest location. Do not claim reclaimed physical bytes until post-delete NAS measurement.

## Reporting

For long work, report compact live checkpoints: app command state, verified files imported (from history), and the next gated step. If a script completes with zero candidates, inspect container-vs-host path translation and a known one-folder API call before declaring the music unmatched.
