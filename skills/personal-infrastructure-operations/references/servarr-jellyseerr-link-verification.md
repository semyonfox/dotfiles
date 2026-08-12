# Servarr + Jellyseerr link verification and repair

Use this when Jellyseerr/Overseerr-style requests look disconnected from Sonarr/Radarr/Jellyfin after NAS/NFS, Docker, or LAN-IP changes.

## Failure pattern

Common symptoms:

- Sonarr health says all download clients/indexers are unavailable.
- Jellyseerr logs show `Unable to get queue from Radarr server` or `connect ETIMEDOUT <old-ip>:8096` for Jellyfin.
- Some Servarr containers are still exited after `/mnt/media`/NFS has already recovered.
- Jellyseerr can load but availability/library sync is stale or wrong.

## Read-only discovery first

1. Check containers:

```bash
docker ps -a --format '{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' \
  | egrep -i 'jellyseerr|jellyfin|sonarr|radarr|prowlarr|qbittorrent|bazarr|lidarr'
```

2. Check NAS/media mount before restarting bind-mount users:

```bash
findmnt -T /mnt/media -o TARGET,SOURCE,FSTYPE,OPTIONS
ls -ld /mnt/media /mnt/media/arrs /mnt/media/arrs/downloads
```

3. Validate the Compose stack using the stack env file. Do not run `docker compose -f stack.yaml ...` without `--env-file stack.env` in Semyon's `server-stacks` convention, because Compose interpolation does not read service `env_file` values:

```bash
cd /home/semyon/server-stacks/servarr
docker compose --env-file stack.env -f stack.yaml config >/tmp/servarr-compose.config
```

## Restart stale Servarr containers after mount recovery

If the mount is healthy but containers are still exited with errors like `error while creating mount source path '/mnt/media/arrs'`, recreate the affected services:

```bash
cd /home/semyon/server-stacks/servarr
docker compose --env-file stack.env -f stack.yaml up -d qbittorrent prowlarr radarr lidarr bazarr sonarr
```

Then probe UI/API ports:

```bash
for port in 8989 9696 7878 8686 8080 6767 5055; do
  printf "%s " "$port"
  curl -sS -o /dev/null -w '%{http_code}\n' --max-time 8 "http://127.0.0.1:$port/" || true
done
```

## Use Arr API keys from config.xml for health/tests

API keys are in each app config. Do not paste keys into chat.

```bash
key=$(python3 - <<'PY'
import xml.etree.ElementTree as ET
print(ET.parse('/home/semyon/server-stacks/data/servarr/sonarr/config/config.xml').findtext('ApiKey'))
PY
)
curl -sS -H "X-Api-Key: $key" http://127.0.0.1:8989/api/v3/health
curl -sS -X POST -H "X-Api-Key: $key" -H 'Content-Type: application/json' \
  http://127.0.0.1:8989/api/v3/downloadclient/testall
curl -sS -X POST -H "X-Api-Key: $key" -H 'Content-Type: application/json' \
  http://127.0.0.1:8989/api/v3/indexer/testall
```

Useful endpoints:

- Sonarr: `8989/api/v3/system/status`, `/qualityprofile`, `/rootfolder`, `/queue`, `/health`, `/downloadclient/testall`, `/indexer/testall`
- Radarr: `7878/api/v3/system/status`, `/qualityprofile`, `/rootfolder`, `/queue`, `/health`, `/downloadclient/testall`, `/indexer/testall`
- Prowlarr: `9696/api/v1/indexer/testall`

If one Prowlarr indexer is genuinely bad, disable only that indexer and its stale proxy in Sonarr/Radarr rather than claiming all indexers are broken.

## Verify Jellyseerr sees Sonarr/Radarr the way its UI does

Jellyseerr stores config in:

```text
/home/semyon/server-stacks/data/servarr/jellyseerr/config/settings.json
```

Redact API keys when reporting. Check configured servers:

```bash
jq -r '.radarr[] | "radarr \(.name) host=\(.hostname):\(.port) default=\(.isDefault) sync=\(.syncEnabled) dir=\(.activeDirectory)"' settings.json
jq -r '.sonarr[] | "sonarr \(.name) host=\(.hostname):\(.port) default=\(.isDefault) sync=\(.syncEnabled) dir=\(.activeDirectory)"' settings.json
```

From inside Jellyseerr, verify container-network reachability:

```bash
docker exec -e SONARR_KEY="$sonarr_key" -e RADARR_KEY="$radarr_key" jellyseerr sh -lc 'node - <<"NODE"
const checks = [
  ["Sonarr status", "http://sonarr:8989/api/v3/system/status", process.env.SONARR_KEY],
  ["Sonarr profiles", "http://sonarr:8989/api/v3/qualityprofile", process.env.SONARR_KEY],
  ["Sonarr root folders", "http://sonarr:8989/api/v3/rootfolder", process.env.SONARR_KEY],
  ["Sonarr queue", "http://sonarr:8989/api/v3/queue?includeUnknownSeriesItems=true", process.env.SONARR_KEY],
  ["Radarr status", "http://radarr:7878/api/v3/system/status", process.env.RADARR_KEY],
  ["Radarr profiles", "http://radarr:7878/api/v3/qualityprofile", process.env.RADARR_KEY],
  ["Radarr root folders", "http://radarr:7878/api/v3/rootfolder", process.env.RADARR_KEY],
  ["Radarr queue", "http://radarr:7878/api/v3/queue?includeUnknownMovieItems=true", process.env.RADARR_KEY]
];
(async()=>{
  for (const [name, url, key] of checks) {
    try {
      const r = await fetch(url, {headers:{"X-Api-Key": key}, signal: AbortSignal.timeout(8000)});
      const body = await r.json().catch(()=>null);
      let detail = "";
      if (body?.appName) detail = body.appName + " " + body.version;
      else if (Array.isArray(body)) detail = "items=" + body.length;
      else if (body?.records) detail = "records=" + body.records.length + " total=" + body.totalRecords;
      console.log(name + ": http=" + r.status + " " + detail);
    } catch(e) { console.log(name + ": FAIL " + e.name + ": " + e.message); }
  }
})();
NODE'
```

Also hit Jellyseerr's own native test endpoints because they match what the UI/settings page validates:

```bash
api=$(jq -r '.main.apiKey' settings.json)
sonarr_body=$(jq -c '.sonarr[0]' settings.json)
radarr_body=$(jq -c '.radarr[0]' settings.json)

curl -sS -X POST -H "X-Api-Key: $api" -H 'Content-Type: application/json' \
  -d "$sonarr_body" http://127.0.0.1:5055/api/v1/settings/sonarr/test
curl -sS -X POST -H "X-Api-Key: $api" -H 'Content-Type: application/json' \
  -d "$radarr_body" http://127.0.0.1:5055/api/v1/settings/radarr/test
curl -sS -H "X-Api-Key: $api" http://127.0.0.1:5055/api/v1/service/sonarr/0
curl -sS -H "X-Api-Key: $api" http://127.0.0.1:5055/api/v1/service/radarr/0
```

## Repair Jellyseerr -> Jellyfin after IP/server-id drift

Jellyfin may run in host network mode. In Semyon's stack, Jellyseerr may need to reach it via `10.0.0.5:8096` or Docker gateway/host address, not the stale LAN IP saved in settings.

Probe from inside Jellyseerr:

```bash
docker exec jellyseerr sh -lc 'node - <<"NODE"
const checks = [
  ["old", "http://192.168.178.24:8096/System/Info/Public"],
  ["host-lan", "http://10.0.0.5:8096/System/Info/Public"],
  ["gateway", "http://172.25.0.254:8096/System/Info/Public"],
  ["docker-host", "http://172.17.0.1:8096/System/Info/Public"]
];
(async()=>{ for (const [name,url] of checks) {
  try { const r=await fetch(url,{signal:AbortSignal.timeout(6000)}); const b=await r.json(); console.log(`${name}: http=${r.status} ${b.ServerName} ${b.Version}`); }
  catch(e){ console.log(`${name}: FAIL ${e.name}: ${e.message}`); }
}})();
NODE'
```

If only the endpoint is stale, update `settings.json` with the reachable IP/port and current Jellyfin server ID. If authenticated Jellyfin calls still fail, check Jellyfin's `ApiKeys` table in `/mnt/media/docker_data/jellyfin/config/data/jellyfin.db`; create/reuse a `Jellyseerr` key only after backing up the DB and settings.

Important Jellyseerr quirk: the Jellyfin scanner uses Jellyseerr DB user `id=1` as the admin and calls Jellyfin with that user's `jellyfinUserId`/`jellyfinDeviceId`. If endpoint + API key work but scans fail with 404, inspect and repair `/home/semyon/server-stacks/data/servarr/jellyseerr/config/db/db.sqlite3` table `user` so admin `id=1` points at the current Jellyfin user ID. Back up the DB first.

After updating Jellyseerr settings/DB:

```bash
docker restart jellyseerr
api=$(jq -r '.main.apiKey' /home/semyon/server-stacks/data/servarr/jellyseerr/config/settings.json)
# Refresh library list, then re-enable wanted library IDs if the refresh disabled them.
curl -sS -H "X-Api-Key: $api" 'http://127.0.0.1:5055/api/v1/settings/jellyfin/library?sync=true'
curl -sS -X POST -H "X-Api-Key: $api" -H 'Content-Type: application/json' \
  -d '{"start":true}' http://127.0.0.1:5055/api/v1/settings/jellyfin/sync
curl -sS -H "X-Api-Key: $api" http://127.0.0.1:5055/api/v1/settings/jellyfin/sync
```

A real success is `Full Scan Complete` in Jellyseerr logs and no new `ETIMEDOUT`, 401, or 404 Jellyfin sync errors.

## Reporting caveats

- Distinguish "Jellyseerr can reach Sonarr/Radarr" from "the whole automation chain is clean". Also test Arr download clients and indexers.
- Sonarr warnings such as `qBittorrent places downloads in the root folder /downloads` mean the integration works but path hygiene is poor. Flag it as a next cleanup, not as broken connectivity.
- Radarr TMDb removed-title warnings and update notices are unrelated to Jellyseerr connectivity.
