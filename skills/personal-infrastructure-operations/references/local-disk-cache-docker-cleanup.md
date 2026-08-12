# Local disk cache + Docker cleanup audit

Use this for Semyon's homelab/server when `/` is filling and the request is to identify or safely reclaim local disk without touching persistent app state or AI session history.

## Read-only audit first

Capture baseline before deleting anything:

```bash
df -hT --exclude-type=tmpfs --exclude-type=devtmpfs --exclude-type=squashfs
du -xhd1 / 2>/dev/null | sort -h
du -xhd1 /home/semyon 2>/dev/null | sort -h | tail -40
docker system df
```

For Docker detail:

```bash
docker system df -v
docker ps -a --format '{{.Names}}\t{{.Status}}\t{{.Image}}'
docker volume ls -qf dangling=true
```

## Irish Rail / NABBER storage check

NABBER runs as the `irish_rail_*` containers. To verify it is genuinely running 24/7, check both container health and recent daemon ingestion logs:

```bash
docker ps --filter 'name=irish_rail' --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'
docker logs --since 2h --tail 80 irish_rail_daemon 2>&1 | tail -80
```

Check current DB size with the configured PG18 user/database, not a hard-coded `postgres` role:

```bash
docker exec irish_rail_db psql -U irish_data -d ireland_public \
  -c "SELECT pg_size_pretty(pg_database_size(current_database())) AS database_size;"
```

The PG18 Timescale container mounts its real data at `/var/lib/postgresql`; an older/named `/var/lib/postgresql/data` volume may exist but be empty. Confirm mounts before judging which volume matters:

```bash
docker inspect irish_rail_db --format '{{range .Mounts}}{{.Name}} -> {{.Destination}} {{.Source}}{{println}}{{end}}'
```

In the June 2026 cleanup, NABBER DB was ~3.4 GiB while `/home/semyon/code/personal/irish-rail-nabber/api/target` was ~9.5 GiB. So when the repo is large, first suspect Rust `target/` build output before blaming the live DB.

## Safe cleanup pattern when approved

Respect explicit exclusions. If Semyon says not to delete AI logs/sessions, avoid `.t3-code`, `.hermes`, `.claude`, `.codex`, provider logs, and session databases entirely.

Common approved disposable targets:

```bash
rm -rf /home/semyon/code/personal/irish-rail-nabber/api/target
find /data/compose/51/data/uploads -mindepth 1 -maxdepth 1 -exec rm -rf {} +
mkdir -p /data/compose/51/data/uploads
rm -rf \
  /home/semyon/.cache/uv \
  /home/semyon/.cache/pip \
  /home/semyon/.cache/pnpm \
  /home/semyon/.cache/node-gyp \
  /home/semyon/.cache/node \
  /home/semyon/.cache/ms-playwright \
  /home/semyon/.cache/puppeteer \
  /home/semyon/.cache/electron \
  /home/semyon/.cache/huggingface \
  /home/semyon/.cache/datalab \
  /home/semyon/.npm/_cacache \
  /home/semyon/.npm/_npx \
  /home/semyon/.local/share/pnpm
mkdir -p /home/semyon/.cache /home/semyon/.npm /home/semyon/.local/share
chown -R semyon:semyon /home/semyon/.cache /home/semyon/.npm /home/semyon/.local/share 2>/dev/null || true
```

Then prune low-risk Docker objects:

```bash
docker container prune -f
docker image prune -a -f
docker builder prune -f
```

## Volume pruning rules

Never blanket-prune all volumes unless explicitly approved and verified. Prefer:

- Remove dangling anonymous volumes after inspecting labels and contents.
- Remove clearly disposable named test volumes such as `*_swim_e2e_pgdata` from old PR/test runs.
- Keep named app DB/data volumes and old migration backups unless Semyon explicitly approves, e.g. `oghma-postgres-data.old-pg17`, `portfolio_*`, active `irish-*`, `uisce_*`, etc.

Inspect large dangling anonymous volumes before removal:

```bash
for v in $(docker volume ls -qf dangling=true); do
  docker volume inspect "$v" --format 'Created={{.CreatedAt}} Labels={{json .Labels}} Mount={{.Mountpoint}}'
  docker run --rm -v "$v":/v:ro alpine sh -c 'du -sh /v 2>/dev/null; find /v -maxdepth 2 -type f 2>/dev/null | sed "s#^/v/##" | head -20'
done
```

Select anonymous dangling volumes by label:

```bash
vols_to_remove=()
while read -r v; do
  [ -z "$v" ] && continue
  labels=$(docker volume inspect "$v" --format '{{json .Labels}}' 2>/dev/null || echo '{}')
  if printf '%s' "$labels" | grep -q 'com.docker.volume.anonymous'; then
    vols_to_remove+=("$v")
  fi
done < <(docker volume ls -qf dangling=true)
[ ${#vols_to_remove[@]} -gt 0 ] && docker volume rm "${vols_to_remove[@]}"
```

## Verification

After cleanup:

```bash
df -h /
docker system df
docker ps --filter health=unhealthy --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'
docker ps --filter 'name=irish_rail' --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'
```

Report before/after `df`, reclaimed GiB, what was deleted, what was deliberately preserved, and live service status.