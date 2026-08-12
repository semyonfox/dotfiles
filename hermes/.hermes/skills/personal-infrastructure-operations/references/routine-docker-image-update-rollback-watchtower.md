# Routine Docker image update with rollback tags and Watchtower

Use this for broad homelab container refreshes where Semyon asks to update Docker apps/images and be ready to rollback.

## Safe update pattern

1. Capture the current running state before pulling/recreating anything:

```bash
TS=$(date +%Y%m%d-%H%M%S)
BDIR="$HOME/docker-image-backups/$TS"
mkdir -p "$BDIR"
docker ps --format '{{.ID}} {{.Names}} {{.Image}} {{.Status}}' > "$BDIR/running-containers.txt"
docker ps -aq | xargs -r docker inspect > "$BDIR/container-inspect.json"
docker image ls --digests > "$BDIR/image-ls-digests.txt"
docker ps -q | xargs -r docker inspect --format '{{.Image}} {{.Config.Image}} {{.Name}}' \
  | sed 's# /# #' | sort -u > "$BDIR/running-imageids-images-containers.txt"
awk '{print $1}' "$BDIR/running-imageids-images-containers.txt" | sort -u > "$BDIR/running-imageids.txt"
: > "$BDIR/rollback-tags.txt"
while read -r imageid; do
  [ -n "$imageid" ] || continue
  short=${imageid#sha256:}; short=${short:0:12}
  tag="local/rollback-running:${TS}-${short}"
  docker tag "$imageid" "$tag"
  echo "$imageid $tag" >> "$BDIR/rollback-tags.txt"
done < "$BDIR/running-imageids.txt"
```

This is not a database backup; it is an image/container-state rollback aid. For stateful app major upgrades, also take service-specific DB/app backups.

2. Prefer a monitor-only Watchtower scan first, but expect local/private build images to produce harmless pull-access errors:

```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower:latest \
  --run-once --monitor-only --no-startup-message 2>&1 | tee "$BDIR/watchtower-monitor-only.log"
```

3. Run the update with logs persisted:

```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower:latest \
  --run-once --cleanup --no-startup-message 2>&1 | tee "$BDIR/watchtower-update.log"
```

If a digest-pinned image causes Watchtower to hang or loop during registry checks, rerun with that container disabled rather than leaving the fleet half-updated:

```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower:latest \
  --run-once --cleanup --no-startup-message \
  --disable-containers immich_redis 2>&1 | tee "$BDIR/watchtower-update-skip-immich-redis.log"
```

## Post-update verification

Run these before reporting success:

```bash
docker ps -a --format '{{.Names}}\t{{.Image}}\t{{.Status}}' \
  | awk 'BEGIN{FS="\t"} $3 !~ /^Up/ || $3 ~ /unhealthy|starting|Restarting/ {print}' | sort

docker system df
```

Then probe key services locally. Use their actual bind IPs; not everything is bound to `127.0.0.1` (Temporal UI in this stack is bound to `10.0.0.5:8233`).

## Pitfalls observed

- Watchtower may stop containers near the end of a run. If interrupted, check for containers that were previously running but are now exited; manually `docker start <name>` if the update did not recreate them. Sonarr was one such case.
- Digest-pinned Immich support images can make Watchtower fall back to a pull path with refs lacking tags. If the run stalls, disable that specific container and complete the rest of the fleet.
- A recreated container can come back with no networks attached. Temporal showed `NetworkSettings.Networks={}` and then failed resolving `postgresql`; fixing was:

```bash
docker network connect temporal-network temporal || true
docker restart temporal
```

Verify with `docker inspect <container> --format '{{json .NetworkSettings.Networks}}'` and logs/health.
- Some containers are intentionally/local-build images (`oghma:*`, `swim-api:*`, `portfolio-*`, etc.) and Watchtower cannot pull them from Docker Hub. Treat pull-access-denied messages for those as expected unless the service actually changed health/state.
- Do not confuse Docker image updates with host Docker Engine / apt package updates. If sudo is needed interactively, use a PTY flow; Hermes may block password piping via `sudo -S`.

## Rollback notes

The `rollback-tags.txt` file maps original running image IDs to `local/rollback-running:<timestamp>-<shortid>` tags. If an updated container breaks, inspect its pre-update config from `container-inspect.json`, retag or edit the compose image reference to the rollback tag, recreate only that service, and verify health/logs before touching the rest of the stack.
