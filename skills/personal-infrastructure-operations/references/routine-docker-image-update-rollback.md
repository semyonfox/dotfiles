# Routine Docker image update with rollback safety

Use this when Semyon asks for a routine Docker/container update across the homelab and wants rollback readiness.

## Safe update pattern

1. Baseline first:
   - `docker version` and `docker compose version`
   - `docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'`
   - `docker system df`
   - list Compose labels/working dirs if you need to understand stack ownership.
2. Create rollback metadata before pulling/recreating anything:
   - Make a timestamped directory, e.g. `~/docker-image-backups/YYYYmmdd-HHMMSS/`.
   - Save current running containers, full inspect JSON, image digests, and image-id/image-name/container mapping.
   - Tag each unique currently-running image ID with a local rollback tag such as `local/rollback-running:<timestamp>-<short-imageid>`.
   - Keep the rollback tag map in `rollback-tags.txt`.
3. Run the update with a tool that recreates from the Docker API (Watchtower one-shot works), capture logs to the backup directory, and use a background process with completion notification for long runs.
4. If a first run is interrupted/killed after containers were stopped, do not assume it rolled back. Inspect stopped containers and rerun/repair deliberately.
5. Verify all services after completion:
   - `docker ps -a` for stopped/unhealthy/starting/restarting containers.
   - Start any unexpectedly stopped service and recheck.
   - Give healthchecks a grace period, then inspect logs for anything still starting/unhealthy.
   - Probe key HTTP services on their actual bind addresses.

## Watchtower pitfalls observed

- Watchtower can hang or spend a long time checking digest-pinned images (example: an Immich Valkey image with a digest-pinned reference). If so, rerun with `--disable-containers <name>` for the problematic digest-pinned container rather than letting the whole maintenance window stall.
- Local-only images (`swim-api:latest`, `oghma:prod-latest`, `portfolio-*`, etc.) will produce registry `pull access denied` warnings. Treat these as expected for local build artifacts unless the stack is supposed to pull from a registry.
- `--cleanup` may remove old image IDs even when rollback tags were created. Verify how many rollback tags still exist after the run; keep the metadata even if some old layer tags were pruned.
- Watchtower may stop a container and be interrupted before recreating it. Explicitly check for newly stopped services like `sonarr`/`qbittorrent` afterwards.
- A recreated container can lose or fail to attach to its intended user-defined network. Symptom: application logs show DNS resolution falling out to public DNS for an internal service name (for example Temporal trying to resolve `postgresql` via `8.8.8.8`). Compare `docker inspect <app>` and its database/dependency networks, then `docker network connect <network> <container>` and restart the app.
- Do not probe only `127.0.0.1`; some stacks intentionally bind to the LAN IP (example: Temporal UI at `10.0.0.5:8233`). Check `docker inspect` port bindings or `docker ps` before declaring a UI down.

## Host Docker package update pattern

If Semyon asks for Docker itself too:

1. Authenticate sudo via PTY/background process; Hermes blocks password piping with `sudo -S`.
2. Run `sudo apt-get update`.
3. Check Docker-related upgrades with:
   `apt list --upgradable 2>/dev/null | grep -Ei '^(docker|containerd|runc|docker-ce|docker-buildx|docker-compose|docker-compose-plugin)' || true`
4. If upgrades exist, upgrade Docker packages carefully and re-verify Docker plus container health. If none exist, report installed versions from `docker version`, `docker compose version`, and `dpkg -l`.

## Minimal final report

Keep the report short and operational:

- backup directory
- scanned/updated/failed counts
- issues fixed
- remaining stopped containers, clearly marking pre-existing ones if known
- host Docker package status
- final health/probe status
