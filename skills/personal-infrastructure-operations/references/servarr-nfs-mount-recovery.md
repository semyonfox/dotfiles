# Servarr NFS mount recovery and poisoned health checks

Use when Sonarr/Radarr/Lidarr/Prowlarr/qBittorrent show broad health failures after `/mnt/media` or the NAS/NFS mount was down.

## Pattern observed

Symptoms in Sonarr health can look like application-level breakage:

- `All download clients are unavailable due to failures`
- `All indexers are unavailable due to failures for more than 6 hours`
- `Unable to communicate with qBittorrent. Name does not resolve`
- `All rss/search-capable indexers are temporarily unavailable`

But the root cause may be Docker containers left exited after an NFS outage. Docker may report mount errors such as:

- `error while creating mount source path '/mnt/media/arrs': mkdir /mnt/media/arrs: no such device`
- `error while creating mount source path '/mnt/media/arrs': mkdir /mnt/media: file exists`

Once the NAS mount is restored, the containers do not always recover automatically; restart/recreate the affected stack services.

## Recovery workflow

1. Verify the mount is back before touching containers:

   ```bash
   findmnt -T /mnt/media -o TARGET,SOURCE,FSTYPE,OPTIONS
   findmnt -T /mnt/media/arrs -o TARGET,SOURCE,FSTYPE,OPTIONS
   ls -ld /mnt/media /mnt/media/arrs /mnt/media/arrs/downloads
   ping -c 2 -W 2 10.0.0.6
   ```

2. Inspect current/stopped Servarr containers:

   ```bash
   docker ps -a --format '{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' \
     | egrep -i 'sonarr|radarr|prowlarr|lidarr|readarr|qbittorrent|qb|jackett|transmission|sab|nzb|bazarr'
   ```

3. Use the stack env file when running Compose from CLI. `env_file: stack.env` inside the Compose file passes variables to containers; it does **not** populate `${DOCKER_DATA}` / `${ARRS_MEDIA}` substitutions for Compose itself.

   ```bash
   cd /home/semyon/server-stacks/servarr
   docker compose --env-file stack.env -f stack.yaml config >/tmp/servarr-compose.config
   docker compose --env-file stack.env -f stack.yaml up -d qbittorrent prowlarr radarr lidarr bazarr sonarr
   ```

4. Verify ports and container state:

   ```bash
   docker ps --format '{{.Names}}\t{{.Status}}\t{{.Ports}}' \
     | egrep -i 'sonarr|radarr|lidarr|prowlarr|qbittorrent|bazarr'

   for port in 8989 9696 7878 8686 8080 6767; do
     printf "%s " "$port"
     curl -sS -o /dev/null -w '%{http_code}\n' --max-time 8 "http://127.0.0.1:$port/"
   done
   ```

5. Use app APIs for actual health, not just port checks. API keys are in each app's `config.xml` under `/home/semyon/server-stacks/data/servarr/<app>/config/config.xml`.

   ```bash
   key=$(python3 - <<'PY'
   import xml.etree.ElementTree as ET
   print(ET.parse('/home/semyon/server-stacks/data/servarr/sonarr/config/config.xml').findtext('ApiKey'))
   PY
   )
   curl -sS -H "X-Api-Key: $key" http://127.0.0.1:8989/api/v3/health | jq -r '.[]? | "[\(.type)] \(.message)"'
   curl -sS -X POST -H "X-Api-Key: $key" -H 'Content-Type: application/json' http://127.0.0.1:8989/api/v3/downloadclient/testall | jq .
   curl -sS -X POST -H "X-Api-Key: $key" -H 'Content-Type: application/json' http://127.0.0.1:8989/api/v3/indexer/testall | jq .
   ```

## Indexer poison after recovery

After containers are back, a single failing Prowlarr indexer can keep Sonarr warnings alive even though the system is basically fixed. In the observed case:

- qBittorrent test became valid after restarting containers.
- Prowlarr itself was healthy.
- `The Pirate Bay` tested valid.
- `1337x` returned `Forbidden` / temporary 429-disabled via Prowlarr.

Smallest safe remediation: disable the broken indexer in Prowlarr and, if Sonarr still has a stale proxy entry, disable RSS/automatic/interactive search for that Sonarr-side proxy rather than deleting settings outright.

Example API pattern:

```bash
prowlarr_key=$(python3 - <<'PY'
import xml.etree.ElementTree as ET
print(ET.parse('/home/semyon/server-stacks/data/servarr/prowlarr/config/config.xml').findtext('ApiKey'))
PY
)
sonarr_key=$(python3 - <<'PY'
import xml.etree.ElementTree as ET
print(ET.parse('/home/semyon/server-stacks/data/servarr/sonarr/config/config.xml').findtext('ApiKey'))
PY
)

# Disable Prowlarr indexer id 3 after confirming it is the broken one.
curl -sS -H "X-Api-Key: $prowlarr_key" http://127.0.0.1:9696/api/v1/indexer/3 \
  | jq '.enable=false' \
  | curl -sS -X PUT -H "X-Api-Key: $prowlarr_key" -H 'Content-Type: application/json' -d @- http://127.0.0.1:9696/api/v1/indexer/3

# Disable Sonarr proxy id 5 after confirming it corresponds to the same broken indexer.
curl -sS -H "X-Api-Key: $sonarr_key" http://127.0.0.1:8989/api/v3/indexer/5 \
  | jq '.enableRss=false | .enableAutomaticSearch=false | .enableInteractiveSearch=false' \
  | curl -sS -X PUT -H "X-Api-Key: $sonarr_key" -H 'Content-Type: application/json' -d @- http://127.0.0.1:8989/api/v3/indexer/5
```

Do not hardcode IDs without listing/testing first; they are instance state.

## Reporting

Lead with the live result: which containers are up, which app health checks are OK, which indexers/download clients tested valid, and what unrelated warnings remain (for example Radarr update/TMDb removed-title warnings).