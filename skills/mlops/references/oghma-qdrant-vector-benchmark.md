# OghmaNotes Qdrant vector benchmark

Use this as a reference pattern when comparing Postgres/pgvector, MariaDB vector search, and Qdrant for OghmaNotes-style RAG workloads.

## Dataset and setup

- Source: real OghmaNotes production embeddings exported from PostgreSQL 18/pgvector.
- Rows: 15,341 embeddings.
- Dimensions: 4096.
- Qdrant version tested: `qdrant/qdrant:latest`, server `1.18.2`.
- Collection: cosine vectors, size 4096, HNSW enabled.
- Test query set: 25 sampled real vectors from the collection, top-10, 5 repeats.
- Recall baseline: exact cosine top-10 computed against the exported vectors.

## Measured results

Load/import:

```text
Postgres export: ~4.1s
Raw TSV export: ~764 MB
Qdrant REST load: ~46.1s
Load rate: ~332 vectors/s
Qdrant storage: ~294 MB
```

Qdrant indexed search:

```text
ANN ef64:
  server median: ~1.70 ms
  client median: ~6.08 ms
  client p95:    ~7.21 ms
  recall@10:     100%

ANN ef128:
  server median: ~2.54 ms
  client median: ~6.89 ms
  client p95:    ~10.11 ms
  recall@10:     100%

ANN ef256:
  server median: ~3.67 ms
  client median: ~8.10 ms
  client p95:    ~9.79 ms
  recall@10:     100%
```

Qdrant exact search:

```text
server median: ~9.33 ms
client median: ~13.87 ms
client p95:    ~15.62 ms
recall@10:     100%
```

Comparison context from the same Oghma investigation:

```text
Postgres 18 pgvector exact scan: ~230 ms
MariaDB indexed vector search:   ~1.2-2 ms warm
Qdrant indexed vector search:    ~1.7-2.5 ms server-side
```

## Interpretation

Qdrant is fast enough to remove vector search as a concern at current Oghma scale and avoids migrating canonical app data away from Postgres. It is a cleaner first sidecar than MariaDB if the app accepts a dedicated vector backend.

Recommended architecture:

```text
Postgres 18:
  canonical users, notes, chunks, auth, jobs, billing, storage metadata,
  permissions, schema migrations, and embedding metadata

Qdrant:
  chunk_id -> 4096-dim vector
  fast ANN search
  rebuildable derived index
```

Search flow:

```text
query text
 -> embed query
 -> Qdrant topK chunk_ids
 -> Postgres fetch chunks/notes/permissions/metadata
 -> rerank/compose response
```

## Decision guidance

- Avoid full Postgres -> MariaDB migration just to solve high-dimensional vector indexing.
- Build a `VectorStore` abstraction first.
- Keep Postgres as source of truth and treat vector stores as rebuildable derived data.
- Add providers in this rough order: `postgres_exact`, then `qdrant`; optionally compare `mariadb_vector` behind the same interface.
- Before productionizing Qdrant, re-test with real user text query embeddings, filters/permissions, deletes/re-embeds, topK 10/20/50, and concurrent load.

## Durable caveat

The benchmark used query vectors sampled from existing embeddings, which is valid for index/latency sanity and recall overlap but not a full search-quality evaluation. Real search quality still needs representative user queries and reranking evaluation.
