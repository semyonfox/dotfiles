# Jellyfin Cloudflare Tunnel and IMVDb triage

Use this when Jellyfin appears up locally but public access/logs look broken, especially after Docker cleanup or tunnel churn.

## Read-only triage first

1. Check containers:
   ```bash
   docker ps -a --filter 'name=jellyfin' --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
   docker inspect jellyfin jellyfin_cloudflared --format 'state={{.State.Status}} health={{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}} error={{.State.Error}}'
   ```
2. Probe Jellyfin locally:
   ```bash
   curl -fsS -i http://127.0.0.1:8096/health
   curl -fsS -i http://127.0.0.1:8096/System/Info/Public
   ```
3. Inspect current logs separately:
   ```bash
   docker logs --tail 120 jellyfin
   docker logs --tail 120 jellyfin_cloudflared
   ```

## Cloudflare Tunnel QUIC flapping

Symptom:

```text
failed to dial to edge with quic: write udp [::]:...->198.41...:7844: sendmsg: network is unreachable
```

Fix the stack command, not random networking:

```yaml
command: tunnel --no-autoupdate --protocol http2 run --token ${TUNNEL_TOKEN}
```

Then validate compose and recreate only the tunnel:

```bash
cd /home/semyon/server-stacks/jellyfin
docker compose --env-file stack.env -f stack.yaml config >/tmp/jellyfin-compose-config.yaml
docker compose --env-file stack.env -f stack.yaml up -d cloudflared
```

Verify:

```bash
docker logs --since 3m jellyfin_cloudflared | grep -E 'Registered tunnel connection|protocol=|ERR|WRN'
# desired: Registered tunnel connection ... protocol=http2
curl -fsS -I https://jellyfin.semyon.ie
# desired: HTTP/2 302 location: web/ or another valid Jellyfin response
```

Cloudflared may still emit ICMP ping warnings when running as its container user; those are not the same as tunnel failure if `protocol=http2` registrations are present.

## IMVDb plugin log spam / metadata errors

Symptoms in `docker logs jellyfin`:

```text
Jellyfin.Plugin.IMVDb.ImvdbClient: ApiKey is unset
MediaBrowser.Providers.Music.ArtistMetadataService: Error in IMVDb
System.Text.Json.JsonException: The JSON value could not be converted to System.Int32. Path: $.results[0].discogs_id
```

The plugin can spam errors during library scans. Disable it by moving the plugin directory and config XML out of the active plugin tree, then restart Jellyfin so it unloads:

```bash
TS=$(date +%Y%m%d-%H%M%S)
DIS=/mnt/media/docker_data/jellyfin/config/plugins.disabled-$TS
mkdir -p "$DIS"
mv /mnt/media/docker_data/jellyfin/config/plugins/IMVDb_5.0.0.0 "$DIS/" 2>/dev/null || true
mv /mnt/media/docker_data/jellyfin/config/plugins/configurations/Jellyfin.Plugin.IMVDb.xml "$DIS/" 2>/dev/null || true
cd /home/semyon/server-stacks/jellyfin
docker compose --env-file stack.env -f stack.yaml restart jellyfin
```

Wait for actual readiness, not just container started:

```bash
for i in $(seq 1 120); do
  body=$(curl -fsS --max-time 5 http://127.0.0.1:8096/health 2>/dev/null || true)
  code=$(curl -sS --max-time 5 -o /tmp/jf_public.json -w '%{http_code}' http://127.0.0.1:8096/System/Info/Public 2>/dev/null || true)
  h=$(docker inspect jellyfin --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}')
  [ "$body" = Healthy ] && [ "$code" = 200 ] && [ "$h" = healthy ] && break
  sleep 1
done
```

Transient `Configuration with key network not found` / 500s can appear if probes hit Jellyfin during startup. Recheck after health is `Healthy` before treating them as persistent failures.

## Reporting

Report separately:

- local Jellyfin health/API result
- public Cloudflare response
- tunnel protocol evidence
- whether IMVDb spam stopped
- any files moved to `plugins.disabled-<timestamp>/`
