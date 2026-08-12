# Jellyseerr / Servarr / Jellyfin request-flow repair

Use this reference when Jellyseerr appears connected to Sonarr/Radarr/Jellyfin but requests do not appear downstream, or Jellyseerr library sync times out after a network/IP change.

## Symptoms observed

- Sonarr/Radarr/Jellyseerr web UIs are reachable, but recent Jellyseerr requests do not show in Sonarr/Radarr.
- Jellyseerr logs repeat errors like `Unable to get queue from Radarr` or Jellyfin sync errors such as `connect ETIMEDOUT <old-ip>:8096`.
- Jellyseerr settings/test endpoints can see Sonarr/Radarr, yet newly requested media remains absent from Arr apps.

## Diagnostic sequence

1. **Check containers and mounts first.** If `/mnt/media` NFS recently failed, Arr containers may still be exited with Docker mount-source errors even after the mount recovers. Restart/recreate the affected Servarr services before chasing app config.
2. **Probe from inside Jellyseerr, not just from the host.** Confirm container-network reachability to:
   - `http://sonarr:8989/api/v3/system/status`
   - `http://radarr:7878/api/v3/system/status`
   - `http://<jellyfin-host>:8096/System/Info/Public`
3. **Use Jellyseerr's own test/service endpoints.** They exercise the path Jellyseerr uses:
   - `POST /api/v1/settings/sonarr/test`
   - `POST /api/v1/settings/radarr/test`
   - `GET /api/v1/service/sonarr/0`
   - `GET /api/v1/service/radarr/0`
4. **Inspect Jellyseerr requests, not just Arr connectivity.** In the Jellyseerr DB, `media_request.status=1` means `PENDING`; pending requests are not sent to Sonarr/Radarr. Confirm `serverId`, `profileId`, `rootFolder`, `media.status`, and `media.externalServiceId` for recent requests.
5. **Check user permissions.** Jellyfin-created Jellyseerr users may only have `REQUEST` permission. Without auto-approve or approval by a manager/admin, requests stay pending even though all integrations test green.

## Status enums useful for SQLite inspection

`media_request.status`:

- `1` = PENDING
- `2` = APPROVED
- `3` = DECLINED
- `4` = FAILED
- `5` = COMPLETED

`media.status`:

- `2` = PENDING
- `3` = PROCESSING
- `4` = PARTIALLY_AVAILABLE
- `5` = AVAILABLE

## Repair patterns

### Jellyseerr -> Jellyfin IP/server/user mismatch

When Jellyfin moved from an old LAN IP to the host network address, Jellyseerr had to be updated from the stale address to the live host endpoint (for this homelab pattern, usually `10.0.0.5:8096`). Public info may work while authenticated calls fail if the stored API key/server/user ID is stale.

Safe sequence:

1. Back up Jellyseerr `settings.json`, Jellyseerr DB, and Jellyfin DB before editing.
2. Probe Jellyfin public info and authenticated API from the Jellyseerr container.
3. If Jellyfin has no reusable Jellyseerr API key, create/reuse one in Jellyfin `ApiKeys` and test it against `/System/Info`.
4. Update Jellyseerr `settings.json` with current Jellyfin IP/port/serverId/apiKey.
5. Ensure Jellyseerr's admin/user row maps to the current Jellyfin user ID; stale Jellyfin user IDs can produce 404s during library scans even when `/Library/MediaFolders` works.
6. Restart Jellyseerr, refresh `/api/v1/settings/jellyfin/library?sync=true`, re-enable intended libraries, then start/poll `/api/v1/settings/jellyfin/sync` until `running=false` and logs show `Full Scan Complete`.

### Requests not appearing in Radarr/Sonarr

If integration tests pass but requests are missing downstream:

1. Query Jellyseerr recent requests. If they are `PENDING`, this is a permission/approval problem, not a networking problem.
2. Check the requesting user's permissions. For Semyon's own Jellyfin-created Jellyseerr login, normal future dispatch should include request + auto-approve for movie/TV if he expects requests to immediately hit Arr apps.
3. Approve only the intended recent requests through Jellyseerr's API/UI; do not bulk-approve months of old pending wishlist entries without asking.
4. Verify logs show `Sent request to Radarr/Sonarr` and `Radarr/Sonarr accepted request`.
5. Verify Arr contains the item by `tmdbId`/`tvdbId`, with monitored=true and the expected root folder/profile.

## Common pitfalls

- Green Jellyseerr Sonarr/Radarr tests prove reachability and settings, not that existing requests were approved or dispatched.
- Jellyseerr full Jellyfin scan can disable libraries during a refresh; re-enable intended libraries after refreshing if the endpoint returns them disabled.
- Do not report “connected” as the final answer if the user's complaint is “my request is not in Sonarr/Radarr.” The real verification is request status plus Arr object presence.
- Avoid approving ancient pending requests just because they are pending. Separate today's/recent intended requests from stale backlog.
