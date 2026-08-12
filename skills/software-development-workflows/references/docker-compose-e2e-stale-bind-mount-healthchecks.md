# Docker Compose E2E stale bind mounts and healthcheck exec failures

Use when an E2E Docker Compose service is reported `unhealthy`, but the service process still responds from the host.

## Symptom

`docker compose ps` shows one service unhealthy, commonly a small mock/fake service. Host-level requests may still pass:

```bash
curl -fsS http://127.0.0.1:<published-port>/health
```

But Docker health logs show exec failures like:

```text
OCI runtime exec failed: exec failed: unable to start container process: current working directory is outside of container mount namespace root -- possible container breakout detected
```

## Diagnosis

Inspect the health log and the container's bind mounts:

```bash
docker inspect <container> --format '{{json .State.Health}}' | jq .
docker inspect <container> --format 'WorkingDir={{.Config.WorkingDir}}
Mounts={{json .Mounts}}
Health={{json .Config.Healthcheck}}'
```

If a bind mount source points at a deleted or old worktree, the already-running process can keep serving files/process state, while later `docker exec`/healthcheck execution fails because Docker cannot enter a valid working directory/mount namespace.

## Fix pattern

Recreate only the affected service from the current checkout rather than bouncing the whole stack:

```bash
docker compose -f docker-compose.e2e.yml up -d --force-recreate <service>
```

Then verify both Docker health and the real endpoint:

```bash
docker compose -f docker-compose.e2e.yml ps <service>
docker inspect <container> --format '{{json .State.Health}}' | jq .
curl -fsS http://127.0.0.1:<published-port>/health
```

## Playwright side pitfall from the same class of failures

If the service is fixed but a Playwright assertion still fails with strict-mode locator errors, inspect the Playwright error context before blaming the service. `locatorA.or(locatorB)` can resolve to two elements when both exist; prefer a single stable locator such as `page.getByRole("main")` once the expected page has loaded.
