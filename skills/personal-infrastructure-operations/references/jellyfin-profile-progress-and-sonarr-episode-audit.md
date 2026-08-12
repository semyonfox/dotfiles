# Jellyfin profile progress transfer and Sonarr episode audit

Use for a user-authorised transfer/reset of one show's playback progress between local Jellyfin profiles, followed by a completeness/order audit.

## Guardrails

- Treat profile/history changes as user data. Confirm the two exact lowercase usernames and the exact series before writing.
- Copy **progress only**: `LastPlayedDate`, `PlayCount`, `PlaybackPositionTicks`, and `Played`. Do not accidentally copy favourites, ratings, likes, parental policy, credentials, or per-user configuration.
- Preserve an existing target profile's unrelated user data. If it already has progress for the show, stop rather than silently overwrite unless the user explicitly directs that outcome.
- A direct SQLite change should occur only while Jellyfin is stopped, in one transaction, with a coherent temporary SQLite backup. Start Jellyfin afterward, wait for the actual API listener (container health can become stale during startup), and remove the temporary rollback copy only after both database and live API verification pass.

## Jellyfin data/API discovery

1. Query Jellyfin's local API with an existing server API key kept in-process; do not print it. Confirm users and password state with `GET /Users`.
2. Resolve a series through the API and enumerate episodes with `ParentId=<series-id>`, `IncludeItemTypes=Episode`, `Recursive=true`, `Fields=UserData`.
3. Note that Jellyfin API GUIDs are compact UUIDs while `jellyfin.db` stores dashed UUIDs. When correlating, normalize with `lower(replace(Id, '-', ''))` (and do the same for `SeriesId`).
4. In `UserData`, the composite primary key is `(ItemId, UserId, CustomDataKey)`. Preserve `CustomDataKey` when copying rows.
5. Scope all changes by the resolved show's `BaseItems` IDs (`Id` plus `SeriesId`), not by a loose title match. A title search can miss ampersand/name variations and one library can contain multiple physical copies of the same episode.
6. After the transfer, verify from the live API that source has zero played/play-count/resume state and target has the expected totals, including any nonzero resume position.

## Watch order and missing-episode audit

1. Separate narrative episodes from extras. A `Specials` item may be a behind-the-scenes documentary rather than a story episode; do not place it into the serial watch order merely because it has a resume point.
2. Compare the local season/episode inventory with an external episode guide and distinguish:
   - absent but deliberately unmonitored seasons;
   - monitored episodes with no file (actual acquisition/ingestion gap);
   - extra/documentary specials.
3. In Sonarr, inspect `/series`, `/episode?seriesId=...`, and `/queue`. Summarize every season as total / monitored / files / monitored-missing.
4. A `RescanSeries` command only rediscovers files already present on the library path; it does **not** search indexers or download episodes. Use it first when asked to scan, poll the command to a terminal `completed` state, then re-check `/episode`.
5. If the rescan leaves monitored episodes missing, report their season/episode/title. Inspect queue warnings separately: qBittorrent's `missing files` warning can explain why a release was never imported, but do not clear the queue, search, or re-download without explicit user approval.

## Example API command

Post a scoped Sonarr rescan:

```json
POST /api/v3/command
{"name":"RescanSeries","seriesId":35}
```

Poll `GET /api/v3/command/<id>` until `status` is `completed`, then query `/api/v3/episode?seriesId=35`.
