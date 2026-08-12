# Compose inter-service DNS fix: resolve-postgres-backups

## Scenario
- Container `resolve-postgres-backups` reported `unhealthy` and logs showed `pg_dump` errors:
  - `could not translate host name "postgres" to address`
- Service relied on `POSTGRES_HOST: postgres` while peer DB container name in this stack was `resolve-postgres`.

## Diagnosis pattern
1. Inspect stack/network mapping and host resolution:
   ```bash
   docker inspect resolve-postgres-backups --format '{{json .NetworkSettings.Networks}}'
   docker exec resolve-postgres-backups sh -lc 'getent hosts postgres || true; getent hosts resolve-postgres || true'
   ```
2. Verify runtime env used by backup job:
   ```bash
   docker exec resolve-postgres-backups env | grep -E 'POSTGRES_HOST|POSTGRES_USER|POSTGRES_DB|POSTGRES_PORT'
   ```
3. Confirm healthcheck endpoint and runtime status:
   ```bash
   docker inspect resolve-postgres-backups --format '{{.State.Health.Status}} {{.State.Status}}'
   docker logs --tail 40 resolve-postgres-backups
   ```

## Fix
- In compose env (`services.backups.environment`), set:
  ```yaml
  POSTGRES_HOST: resolve-postgres
  ```
  (the exact internal service name used in compose, not generic `postgres`)

- Recreate only affected service:
  ```bash
  cd /home/semyon/server-stacks/resolve
  docker compose --env-file stack.env -f stack.yaml up -d backups
  ```

## Validation
- `docker exec resolve-postgres-backups sh -lc 'getent hosts resolve-postgres || true'` returns DB IP
- `docker inspect ...` shows `State.Health.Status=healthy`
- Optional manual backup command succeeds:
  ```bash
  docker exec resolve-postgres-backups /backup.sh
  ```

## Notes
- For transient startup behavior, Docker health status can stay `starting` for a short interval before reaching `healthy`.
- If unhealthy persists, re-check that DB service and backups service are on same compose network and that DB is actually healthy.