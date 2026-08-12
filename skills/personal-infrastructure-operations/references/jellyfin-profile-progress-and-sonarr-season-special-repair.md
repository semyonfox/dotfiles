# Jellyfin profile progress transfer and Sonarr season-special repair

Use for family-profile setup, moving a show’s watched/resume state, or diagnosing a show whose seasonal finale / Christmas special did not arrive.

## Jellyfin profiles

1. Query `GET /Users` with an existing local admin API key; do not print the key. Verify lowercase user names case-insensitively and inspect `HasPassword` / `HasConfiguredPassword`.
2. Create a missing passwordless profile through `POST /Users/New` with JSON body:
   ```json
   {"Name":"michelle","Password":""}
   ```
   A request body is required; a query-only call returns HTTP 400.
3. Re-query live users after mutation. Do not assume a profile was created from a successful-looking request alone.

## Copying a show’s progress

- First enumerate the canonical series and child episodes through Jellyfin’s user-items API. Check the exact `SeriesId`, because database UUIDs are hyphenated while API IDs are compact hexadecimal.
- A show may have watched state on several physical versions of an episode. Copy every matching `UserData` record, not only one API-visible representative.
- “Progress” means `LastPlayedDate`, `PlayCount`, `PlaybackPositionTicks`, and `Played`; do **not** silently transfer favourites, ratings, likes, or user-specific audio/subtitle preferences.
- Jellyfin’s generic playstate API is unreliable for restoring inactive-user resume positions. For an exact transfer, briefly stop Jellyfin, make a coherent SQLite rollback copy with Python’s `Connection.backup()`, transactionally update `UserData`, then restart. Preserve non-progress target fields on conflict and clear only the source progress fields.
- Verify after restart through both database/API semantics: source has no played/playcount/resume state; target has the matching watched count and exact resume ticks. Remove the temporary private rollback copy only after this succeeds.

## Missing Sonarr episodes / specials

1. Sonarr `RescanSeries` only discovers files already on disk; it does **not** search indexers or download a missing episode.
2. Compare Sonarr’s `monitored`, `hasFile`, and per-season counts. Unmonitored earlier seasons are intentional scope, not an ingestion failure.
3. Holiday finales are often stored as `SxxE07` after six regular episodes. Keep narrative watch order as E01–E06 → Christmas finale → next season. Behind-the-scenes entries in Jellyfin Specials are not narrative episodes.
4. Inspect `GET /history/series?seriesId=...`: a `grabbed` event without a corresponding `downloadFolderImported` event proves Sonarr selected a release but never imported that episode.
5. Run interactive `GET /release?episodeId=...` before changing profiles. If viable releases are rejected with `Release in queue already meets cutoff`, stale Sonarr queue records are blocking a replacement search.
6. Remove only the exact stale *Sonarr* per-episode queue entries with `removeFromClient=false` unless removal from qBittorrent is explicitly approved. Re-run `EpisodeSearch`.
7. If a replacement stalls, blocklist that exact Sonarr queue release and use a distinct approved interactive result. Do not blindly clear all queue records or delete downloader data.
8. Poll until `hasFile=true`, then verify Jellyfin’s live item list contains each episode. A healthy Docker container is not proof that the media server has indexed the new files.

## Useful commands/endpoints

- Sonarr: `POST /api/v3/command` with `{ "name": "RescanSeries", "seriesId": <id> }`
- Sonarr search: `{ "name": "EpisodeSearch", "episodeIds": [ ... ] }`
- Sonarr interactive releases: `GET /api/v3/release?episodeId=<id>`; download a selected approved release with `POST /api/v3/release`.
- Sonarr queue: `GET /api/v3/queue?pageSize=1000`; targeted removal `DELETE /api/v3/queue/<id>?removeFromClient=false&blocklist=false`.

Never expose API keys, full download URLs, magnets, or torrent metadata in chat/log summaries.
