# Local disk + Docker storage audit

Use for read-only audits when Semyon asks what is using space on the homelab/server local disk, especially when a Docker-hosted database may be suspected.

## Read-only probe pattern

1. Capture filesystem pressure first:

```bash
df -hT --exclude-type=tmpfs --exclude-type=devtmpfs --exclude-type=squashfs
```

Distinguish local root disk from `/mnt/media` NFS/NAS. Do not conflate NAS usage with local NVMe pressure.

2. Get broad local attribution without crossing filesystems:

```bash
du -xhd1 / 2>/dev/null | sort -h

du -xhd1 /home/semyon 2>/dev/null | sort -h | tail -40

du -xhd1 /var 2>/dev/null | sort -h

du -xhd2 /data 2>/dev/null | sort -h | tail -50
```

Use `-x` so NFS/media mounts do not dominate the local disk audit.

3. Ask Docker for logical reclaimability:

```bash
docker system df
docker system df -v
```

Treat `docker system df -v` as logical/reclaimability evidence, not a deletion plan. Never blindly prune volumes; inspect names, mounts, and active containers first.

4. For a suspected Docker database, inspect the live container mounts and query the database size from inside the container where possible:

```bash
docker inspect <container> --format '{{range .Mounts}}{{.Name}} -> {{.Destination}} {{.Source}}{{println}}{{end}}'
docker exec <container> sh -lc 'printenv | sort | grep -E "POSTGRES|PG|DB|DATABASE"'
docker exec <container> psql -U <user> -d <db> -c "SELECT pg_size_pretty(pg_database_size(current_database())) AS database_size;"
```

For Timescale/Postgres, also list largest relations/chunks:

```sql
SELECT schemaname, relname,
       pg_size_pretty(pg_total_relation_size(format('%I.%I', schemaname, relname)::regclass)) AS total_size
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(format('%I.%I', schemaname, relname)::regclass) DESC
LIMIT 10;
```

5. Compare database storage against repo/build artifacts and caches. For Rust services, `target/debug` and `target/release` can dwarf the live database and are rebuildable. Check:

```bash
du -xhd2 /home/semyon/code/personal/<repo> 2>/dev/null | sort -h | tail -50
```

## Reporting style

- Lead with capacity and whether it is warning vs emergency.
- Give a ranked table of largest users and safe cleanup candidates.
- Explicitly answer the suspected culprit question, e.g. “the live DB is ~3.4G; the repo build artifacts are ~9.5G, so the DB is not the main problem.”
- State that no deletion was done unless Semyon explicitly approved cleanup.
- For cleanup candidates, separate safer cache/build artifacts from risky Docker volumes/app uploads.

## Irish Rail / NABIRD-specific notes from prior audit

- The `irish_rail_db` container used PostgreSQL 18/Timescale with `POSTGRES_USER=irish_data`, `POSTGRES_DB=ireland_public`, and `PGDATA=/var/lib/postgresql/18/docker`.
- The active PG18 data was in an anonymous Docker volume mounted at `/var/lib/postgresql`, while the named `irish-rail-nabber_postgres_data` volume mounted at `/var/lib/postgresql/data` appeared unused/empty. Always verify current mounts rather than assuming the named volume is live.
- In the checked state, the live DB was about 3.4 GiB, while `/home/semyon/code/personal/irish-rail-nabber/api/target` was about 9.5 GiB. Rust build artifacts were the bigger local Irish Rail storage user.
