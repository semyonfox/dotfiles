---
name: docker-maintenance
description: "Use when safely refresh, recover, and verify a multi-stack Docker host, including Watchtower maintenance and zombie-container recovery."
version: 1.0.0
created_by: agent

metadata:
  harness: [hermes]
---

# Docker Maintenance

Use for user-authorized image refreshes, Docker daemon recovery, broad container health checks, or post-maintenance fault monitoring on a multi-stack host.

For compose DNS/inter-service host resolution incidents (`could not translate host name` / incorrect service host env var), see `references/compose-interservice-dns-hostname-resolution.md`.

## Safety model

- Image refreshes and a Docker daemon restart can interrupt every stack. Explicit authorization is required for a host-wide refresh/restart.
- Inventory before mutation. Save a timestamped pre-change artifact containing `docker ps -a`, relevant `docker inspect` JSON, image/container mapping, and recent logs for any already-unhealthy service.
- Do not use `docker system prune` as part of a normal update. Preserve images until post-update health is verified and a rollback path is known.
- Never disclose secrets from compose env files, inspect output, or logs.

## Whole-host image refresh

1. Baseline: record Docker/Compose version, `docker ps -a`, health exceptions, ports, `docker system df`, and compose ownership labels.
2. Tag each distinct running image ID locally for rollback before pulling/recreating. Preserve the tag map in the maintenance artifact.
3. For a Watchtower one-shot, capture its logs externally while it runs. `Found new …` means image discovery only; it does not prove the service has restarted.
4. Wait for the one-shot process to exit before verification. A `--cleanup` run may delete its own runner container, so its in-container logs are unavailable afterward.
5. Local images and digest-pinned images may report registry pull warnings. Classify them separately from real update failures rather than treating every warning as an outage.
6. Check all containers after completion. Wait through bounded healthcheck grace periods, then use service-specific HTTP/API probes on the actual published address.

## Dormant-service preservation before pruning

Use this when a user wants a little-used Docker service taken down but recoverable after normal Docker cleanup.

1. Inventory the exact service **before** stopping it: container ID/name, image, restart/auto-remove policy, Compose ownership, mounts, networks/ports, and persistent-data size. Inspect selectively and redact/avoid command, environment, labels, and full inspect output in chat because they can contain secrets.
2. Identify persistence correctly. Named volumes normally survive `docker system prune` without `--volumes`, but do not treat that as the only copy. Bind-mounted state may sit behind permission-restricted service accounts; use a read-only helper container to size/archive it rather than assuming the interactive host user can traverse the path.
3. Create a timestamped, mode-`0700` archive directory **outside Docker's data root**. While services are stopped, archive each persistent path/volume through a read-only mount, test each archive (`tar -tzf`), and save SHA-256 checksums. Preserve Compose definitions and a non-secret reconstruction note; full metadata should be stored only if access is restricted and never reported verbatim.
4. Stop the requested service(s) deliberately. A Compose service with a related tunnel/proxy may require both the app and its ingress stopped. `docker compose stop`/`docker stop` retains containers for easy restart; `docker compose down` removes them but normally retains named volumes unless `-v` is used.
5. Do not promise an individual stopped container is prune-proof: unfiltered `docker container prune` and `docker system prune` remove stopped containers, and `docker system prune --volumes` can remove unused volumes. The external verified archive is the durable safeguard. State the exact normal restart command and the recovery path if the container is later pruned.
6. Re-check final container state, retained named volumes, archive integrity, checksums, ownership, and permissions. Docker helper containers often create root-owned archives; after verification, explicitly `chown` them to the intended user and use mode `0600` for archive files (or otherwise ensure the user can read them without exposing secrets).
7. If a target container disappears while stopping (for example because it was auto-removed or another owner reconciled it), do not assume its bind data disappeared. Inspect the persistent host path through a read-only helper container, archive it, record only non-secret reconstruction facts, and report that the original container itself is no longer restartable.

## Disk-pressure cache reclamation

Use this only after a read-only baseline (`df -h /`, `docker system df`, `docker ps -a`) and explicit cleanup approval.

1. Start with `docker builder prune -af`: it removes unused BuildKit cache and does not stop containers or remove their images/volumes.
2. Re-check free space and health state. If the user explicitly authorises removal of rollback images, run `docker image prune -a -f`; this removes only images referenced by no container, but sacrifices local rollback/pull-free rebuild history.
3. Never include `docker volume prune` in a broad cache command. Inspect dangling volumes individually; app/database volumes may look unused while still being valuable recovery data.
4. Verify with `df -h /`, `docker system df`, and `docker ps --filter health=unhealthy`. Treat the before/after filesystem free-space delta as the authoritative reclaimed-space figure: `docker system df` reclaimable estimates can differ from the actual BuildKit prune result because of shared/cache accounting. Report reclaimed space, running-service health, and non-running containers deliberately left untouched.

When Docker is no longer the primary consumer, audit `/tmp`, package-manager caches, and logs separately. Preserve active temp worktrees (check `lsof +D <path>`) and do not clear Gradle caches while a Gradle/Android build is live. Prefer narrowly identified runtime caches (such as Metro or Node compile-cache directories) over broad `/tmp` deletion: `/tmp` often contains unreferenced but still valuable generated outputs, review worktrees, and agent handoff material.

## NFS-backed stack recovery after a Docker/NAS ordering failure

When Docker tries to restore bind-mounted containers before an NFS mount (for example `/mnt/media`) is available, containers can remain exited even after the mount returns. First prove the mount is the real mounted filesystem (`mountpoint` plus `df`), inspect the affected containers' mount errors and restart policies, and group them by Compose stack. Then start/recreate only the blocked services; do not restart Docker or prune the host as a shortcut.

For Compose services that lost network attachments during the outage, a plain `docker start` can leave a database running with no Compose networks, while application containers keep failing DNS resolution. Recreate the dependency first from its source-of-truth Compose file, preserving its named volume, then recreate dependent APIs so Docker DNS is rebuilt:

```bash
docker compose -f /absolute/path/stack.yaml --env-file /absolute/path/stack.env \
  up -d --force-recreate db
docker compose -f /absolute/path/stack.yaml --env-file /absolute/path/stack.env \
  up -d --force-recreate api api-dev
```

Verify `docker inspect` reports the expected networks and IPs, then use the service's actual health/API endpoint. A deliberate `404` from `/` still proves the web server is reachable; do not call it an outage without checking the app's intended route. Start independent NFS-backed services only after their data mounts are confirmed accessible.

Do not repeatedly restart GPU-backed services when Docker fails before process start because an expected host NVIDIA library is missing. That is a host driver/runtime mismatch, not an NFS recovery. Restore/reconcile the driver/runtime deliberately (and obtain approval if it requires package or reboot work), or get explicit approval to disable acceleration; keep data services such as Postgres/Redis separate and recoverable meanwhile.

## Zombie-container recovery

A container can appear `running` while its host PID is `<defunct>`. If Docker reports that the PID is a zombie and refuses `restart` or `rm -f`, a user-authorized Docker daemon restart is the practical repair.

1. Save the pre-restart running-container baseline plus inspect/log artifacts.
2. Authenticate sudo through a PTY; never request or expose the password in ordinary chat text.
3. Restart Docker with `sudo systemctl restart docker`; confirm `systemctl is-active docker`.
4. Compare the new `docker ps -a` against the baseline. Restart policies can fail to restore containers whose previous state was stopped/zombie. Start only the exact baseline containers that remain unexpectedly stopped.
5. Give dependency chains time to settle. An app may initially fail health checks while its database is starting or while it performs a first-start migration/import. Verify again after a bounded grace period before escalating.

## Compose service DNS and health triage

When a container stays unhealthy or errors with `could not translate host name`, start with intra-stack DNS checks before deep code changes.

1. Confirm the service is attached to the expected compose network and that service names are resolvable inside the same container:
   ```bash
   docker inspect <container> --format '{{json .NetworkSettings.Networks}}'
   docker exec <container> sh -lc 'getent hosts <service-name> || true; getent hosts <container-name> || true'
   ```
2. Verify the database host variable actually points at a resolvable service name, not an arbitrary DNS alias:
   ```bash
   docker exec <container> env | grep -E 'POSTGRES_HOST|DB_HOST|PGHOST'
   ```
3. Edit compose to use the exact compose service name (for example `resolve-postgres`) when another container resolves via internal bridge DNS. Avoid hardcoded aliases unless they are defined in `networks`/`aliases`.
4. Recreate only the affected service and wait for a full health cycle; if startup includes cron-first behavior, expect a few minutes before first health probe success.
5. Recheck with explicit state and logs after at least two bounded check intervals:
   ```bash
   docker inspect <container> --format '{{.State.Health.Status}} {{.State.Status}} {{.RestartCount}}'
   docker logs --since 2m <container>
   ```

## Post-maintenance verification and log triage

1. Require no unexpected `Exited`, `Restarting`, or `unhealthy` containers. Explicitly distinguish intentional one-shot/test containers from persistent services.
2. Probe the primary services the user relies on, plus each initially failed service. A healthy container is necessary but not sufficient.
3. Scan logs from the maintenance start time for fatal/error patterns, then inspect context rather than reporting raw grep matches as failures:
   - Database-connection failures during dependency startup can be transient if the service later becomes healthy and its API passes.
   - Persistent authentication errors indicate a monitoring/integration configuration issue even when the main application remains up.
   - A plugin that fails due to missing external-service credentials should not be silently disabled; it needs credentials or an explicit user decision to remove that feature.
4. Report concrete final state: recovered containers, verified probes, persistent degraded integrations, and unrelated ad-hoc/anonymous build containers left untouched.

## Verification commands


```bash
docker ps -a --format '{{.Names}}\t{{.Image}}\t{{.Status}}'
docker ps --filter health=unhealthy --format '{{.Names}}\t{{.Status}}'
docker inspect <container> --format '{{.State.Status}} {{if .State.Health}}{{.State.Health.Status}}{{end}}'
docker logs --since '<maintenance-start ISO timestamp>' <container>
```

For an HTTP health endpoint, use a timeout-bounded `curl -fsS --max-time 15 <url>` and report the real status/result.
