# Servarr + Jellyseerr + Jellyfin repair pattern

Use this when Jellyseerr/Sonarr/Radarr show broken download/indexer/media-server health after NAS/NFS, IP, or container restarts.

## Symptoms from the session

- Sonarr health showed all download clients unavailable and all indexers unavailable.
- Servarr containers had exited with Docker mount errors against `/mnt/media/arrs` after the NAS/NFS mount was restored.
- Jellyseerr could reach Sonarr/Radarr after those containers were restarted, but Jellyfin scans timed out against an old LAN IP (`192.168.x.x:8096`).
- After changing Jellyseerr's Jellyfin host, scans moved from timeout to 404 because the stored Jellyfin server/user identity was stale.

## Safe repair sequence

1. **Verify storage first**
   - Check `/mnt/media` with `findmnt`, `ls -ld /mnt/media/arrs`, and a quick NAS ping before restarting media containers.
   - If `/mnt/media` is an NFS mount and is now healthy, dead containers may still need explicit recreation/restart.

2. **Restart Servarr with the stack env loaded**
   - In `/home/semyon/server-stacks/servarr`, use `docker compose --env-file stack.env -f stack.yaml ...`.
   - Plain `docker compose -f stack.yaml` may warn that `TZ`, `DOCKER_DATA`, and `ARRS_MEDIA` are unset and can produce invalid bind specs.
   - Recreate/start the failed services (`qbittorrent`, `prowlarr`, `radarr`, `lidarr`, `bazarr`, plus affected dependents such as `sonarr`).

3. **Use app APIs for verification, not just container status**
   - Read API keys from each app's `config.xml` locally, but do not print them.
   - Sonarr checks:
     - `GET /api/v3/health`
     - `POST /api/v3/downloadclient/testall`
     - `POST /api/v3/indexer/testall`
   - Prowlarr checks:
     - `POST /api/v1/indexer/testall`
   - If one indexer is externally broken (e.g. 1337x returning Forbidden), disable just that indexer in Prowlarr and disable/prune the corresponding proxy in Sonarr; keep working indexers enabled.

4. **Verify Jellyseerr links from inside the Jellyseerr container**
   - Inspect `/home/semyon/server-stacks/data/servarr/jellyseerr/config/settings.json` but redact API keys/tokens.
   - Probe `http://sonarr:8989/api/v3/system/status` and `http://radarr:7878/api/v3/system/status` from `docker exec jellyseerr` with the configured keys.

5. **Fix Jellyseerr ↔ Jellyfin carefully**
   - Find the live Jellyfin endpoint first. Jellyfin may run in `network_mode: host`, so `jellyfin:8096` can fail while `10.0.0.5:8096`, `127.0.0.1:8096` on host, or Docker gateway addresses work.
   - Test public Jellyfin info: `/System/Info/Public`.
   - Test authenticated Jellyfin info using the Jellyseerr API key: `/System/Info`.
   - If Jellyseerr has no working Jellyfin API key, create/reuse an API key in Jellyfin's DB `ApiKeys` table, backing up the DB first.
   - Update Jellyseerr `settings.json` with the live Jellyfin IP/port, current server ID, name, and API key; back up settings first.
   - Restart Jellyseerr.
   - Refresh Jellyseerr libraries through its API and re-enable the intended libraries if the refresh resets them disabled.

6. **Stale Jellyfin user mapping pitfall**
   - Jellyseerr's Jellyfin scanner uses admin user id `1` from its SQLite DB (`config/db/db.sqlite3`) for `jellyfinUserId` and `jellyfinDeviceId`.
   - If the configured Jellyfin user ID no longer exists, scans can fail with 404 even though the Jellyfin host and API key are valid.
   - Map Jellyseerr admin user id `1` to the current Jellyfin `semyon` user ID from Jellyfin's `Users` table, backing up Jellyseerr DB first.
   - Then restart Jellyseerr and run a Jellyfin full scan.

## Verification target

- Jellyseerr can call Jellyfin from inside the container:
  - `/System/Info/Public` returns 200.
  - `/System/Info` with Jellyseerr token returns 200.
  - `/Library/MediaFolders` returns 200 and lists expected libraries.
- Jellyseerr full Jellyfin scan reaches `Full Scan Complete`.
- No new `ETIMEDOUT`, `Jellyfin API`, or `Sync interrupted` errors appear after the repair window.
- Jellyseerr download tracker logs show Sonarr/Radarr queues instead of `Unable to get queue` errors.
