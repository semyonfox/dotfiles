# Postgres vs MariaDB performance triage

Use this when a user asks whether to migrate a live/product app from PostgreSQL to MariaDB/MySQL for performance or future-proofing.

## Core lesson

Do not answer from generic database stereotypes. Inspect the running workload shape first, then decide whether the bottleneck is the database engine or the schema/query/resource design.

For AI/search-heavy apps, especially notes/RAG products, PostgreSQL may be the better strategic base because of `pgvector`, `pg_trgm`, JSONB, full text/search options, transactional correctness, and mature indexing. MariaDB/MySQL can be excellent for CRUD workloads, but migration pain is rarely justified if the real pressure point is vector search, missing indexes, memory caps, object storage, queueing, or LLM latency.

## Minimum evidence to collect before recommending migration

1. Current DB engine/version and installed extensions.
2. DB size and largest tables.
3. Table row counts and total relation sizes.
4. Existing indexes, especially vector/text/search indexes.
5. Runtime resource limits and live usage for DB/cache/app containers.
6. Slow query evidence if available: `pg_stat_statements`, app logs, `EXPLAIN ANALYZE`.
7. Whether the app uses engine-specific features: pgvector, trigram, JSONB, Postgres search, transaction/isolation assumptions.

## Useful Postgres probes

```bash
# Container inventory / resource snapshot
docker ps --filter name=<stack-prefix> --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'
docker stats --no-stream --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}'

# Basic DB shape
docker exec <postgres-container> psql -U <admin-user> -d <db> -Atc "
select current_database(), version();
select 'db_size', pg_size_pretty(pg_database_size(current_database()));
select 'tables', count(*) from information_schema.tables where table_schema not in ('pg_catalog','information_schema');
"

# Extensions and search/vector-related indexes
docker exec <postgres-container> psql -U <admin-user> -d <db> -Atc "
select extname from pg_extension order by extname;
select schemaname, tablename, indexname
from pg_indexes
where indexdef ilike '%vector%' or indexdef ilike '%gin%' or indexdef ilike '%hnsw%' or indexdef ilike '%ivfflat%'
order by schemaname, tablename, indexname;
"

# Largest/user tables and scan patterns
docker exec <postgres-container> psql -U <admin-user> -d <db> -P pager=off -c "
select schemaname||'.'||relname as table,
       n_live_tup,
       pg_size_pretty(pg_total_relation_size(relid)) as total_size,
       seq_scan,
       idx_scan
from pg_stat_user_tables
order by pg_total_relation_size(relid) desc
limit 20;
"

# Inspect a suspected hot table
docker exec <postgres-container> psql -U <admin-user> -d <db> -P pager=off -c "\d+ app.embeddings"
```

## Interpreting results

- Small DB, low CPU/memory, and missing indexes means: tune Postgres, do not migrate engines.
- A large embeddings table with no HNSW/IVFFlat index means semantic search will likely degrade as data grows.
- Very large vector dimensions, e.g. 4096, can dominate DB size quickly; consider smaller embeddings or compression/quantization if quality allows.
- A tiny Postgres memory cap, e.g. 256 MB, is a resource allocation issue, not a reason to switch DB engines.
- If Redis/cache has much more memory than Postgres in a search-heavy app, reconsider memory allocation before engine migration.

## Recommendation shape

Give a direct verdict first:

- "Stay on Postgres" when the workload uses vector/search/Postgres extensions and bottlenecks are tunable.
- "Consider MariaDB/MySQL" only when the app is CRUD-heavy, does not depend on Postgres-specific capabilities, hosting/ops strongly favor MySQL-compatible DBs, and migration cost is still low.

Then list the concrete next moves in priority order, e.g.:

1. Add vector/text indexes.
2. Enable/query `pg_stat_statements` and profile slow queries.
3. Raise DB memory/resources if capped too low.
4. Revisit embedding dimensions/storage strategy.
5. Add app/cache/background-job optimizations.

Avoid framing migration as future-proofing when it would remove capabilities the product is likely to need.
