# Oghma PG18 upgrade, Jenkins persistence, and worker Redis pitfall

Use this reference when upgrading or verifying OghmaNotes homelab database/runtime deployment.

## PG17 -> PG18 safe upgrade pattern

For Oghma's Dockerized Postgres/pgvector service:

1. Take logical dumps of each app database and a raw volume tarball before changing containers.
2. Do not point PostgreSQL 18 at a PostgreSQL 17 data directory.
3. Use the PG18 Docker mount layout:

```yaml
volumes:
  - postgres-data:/var/lib/postgresql
```

not the old PG17-style mount:

```yaml
volumes:
  - postgres-data:/var/lib/postgresql/data
```

4. Restore into a fresh PG18 volume and verify version/extensions/counts before switching names.
5. Move/copy the verified PG18 data back to the canonical Docker volume name:

```text
oghma-postgres-data
```

6. Preserve the old PG17 volume as an explicit old copy, e.g.:

```text
oghma-postgres-data.old-pg17
```

7. Mark the canonical volume external in Compose so stack operations do not recreate/delete it casually:

```yaml
volumes:
  postgres-data:
    name: oghma-postgres-data
    external: true
```

## Oghma verified target shape

Expected Oghma Postgres stack settings after the upgrade:

```yaml
services:
  postgres:
    image: pgvector/pgvector:0.8.2-pg18
    mem_limit: 1g
    volumes:
      - postgres-data:/var/lib/postgresql
```

Expected runtime facts:

```text
Postgres: PostgreSQL 18.4
pgvector: 0.8.2
canonical volume: oghma-postgres-data
old PG17 copy: oghma-postgres-data.old-pg17
```

## Verification checklist

Run these checks before declaring the upgrade done:

- container healthy and image is `pgvector/pgvector:0.8.2-pg18`
- memory limit is 1 GiB
- mount is `oghma-postgres-data:/var/lib/postgresql`
- `select version()` reports PostgreSQL 18.x
- `pg_extension` includes `vector=0.8.2`
- database names remain `oghma`, `oghma_dev`, and `postgres`
- key counts match pre-upgrade expectations for both prod/dev
- Oghma migrations report `all migrations already applied`
- prod/dev health endpoints return HTTP 200
- app and worker containers have no fresh DB/Redis error loops

## Jenkins persistence model

Oghma app deploys are not driven by the Oghma Compose service for app/worker containers. Jenkins jobs build and recreate app/worker containers directly from the app repo:

```text
oghma-prod: APP_BRANCH=main, ENV_FILE=/home/semyon/server-stacks/jenkins/env/oghma-prod.env
oghma-dev:  APP_BRANCH=dev,  ENV_FILE=/home/semyon/server-stacks/jenkins/env/oghma-dev.env
```

Jenkins deploy stages run app and worker containers with:

```bash
docker run --env-file "$ENV_FILE" ...
```

Jenkins app pushes recreate only app/worker containers. They do not recreate `oghma-postgres`, so a verified PG18 Postgres/volume persists across normal app deploys.

When changing persistent stack config, update both relevant locations if both exist:

```text
/home/semyon/server-stacks/oghma/stack.yaml                # live stack copy
/home/semyon/code/personal/server-stacks/oghma/stack.yaml  # tracked repo copy
```

Then commit/push via the `server-stacks` repo. For cautious rollout, push to `origin/dev`, open a PR to `main`, wait for GitHub checks, then merge.

## Env/secrets verification without leaking values

Do not print secrets. Check presence, length, and short hashes/fingerprints for required keys in:

```text
/home/semyon/server-stacks/jenkins/env/oghma-prod.env
/home/semyon/server-stacks/jenkins/env/oghma-dev.env
```

Important env keys include:

```text
DATABASE_URL
MIGRATION_DATABASE_URL
NEXTAUTH_URL
NEXTAUTH_SECRET
STORAGE_ENDPOINT
STORAGE_BUCKET
STORAGE_ACCESS_KEY
STORAGE_SECRET_KEY
REDIS_HOST
REDIS_PORT
LLM_API_KEY
EMBEDDING_API_KEY
RERANK_API_KEY
SES_FROM_EMAIL
AWS_REGION
```

Oghma app secrets currently live in Jenkins runtime env files, not mostly in Jenkins Credentials UI. Jenkins Credentials is used for Git checkout (`github-pat`). Phrase this accurately: secrets are loaded through Jenkins env files.

## Manual compose Redis pitfall

Do not assume `server-stacks/oghma/.env.{prod,dev}` matches Jenkins env files. Manual Compose recreates can use the local `.env` files, while Jenkins deploys use `/home/semyon/server-stacks/jenkins/env/oghma-{dev,prod}.env`.

If local Oghma app/worker containers are manually recreated and `REDIS_HOST`/`REDIS_PORT` are missing, BullMQ falls back to localhost Redis and workers emit repeated blank logs like:

```text
Worker error:
```

Root cause can be hidden because Node `AggregateError` may have an empty `.message`. Temporarily log richer fields:

```js
console.error('Worker error debug:', {
  name: err?.name,
  message: err?.message,
  code: err?.code,
  command: err?.command,
  stack: err?.stack,
  raw: String(err),
});
```

The durable fix is to ensure both Jenkins env files and local stack env files contain:

```text
REDIS_HOST=oghma-redis
REDIS_PORT=6379
```

Then recreate app/worker containers and verify worker logs are quiet over a fresh time window.
