# OghmaNotes cloud vector DB decision notes (4096-dim embeddings)

Use when advising Semyon on OghmaNotes vector storage/search after the move away from homelab hosting toward Cloudflare + Neon/off-prem services.

## Current fixed constraint

- OghmaNotes embeddings are currently `4096` dimensions and Semyon wants dimensions to stay as-is.
- This makes Cloudflare Vectorize unsuitable unless docs/limits change: Cloudflare Vectorize documented max was `1536` dimensions on 2026-06-18.
- Neon/pgvector remains useful for canonical Postgres, but pgvector HNSW indexing does not support `vector(4096)`; `vector` HNSW is up to 2000 dims and `halfvec` up to 4000 dims. Exact scan is viable at small scale but not the long-term indexed vector answer for 4096-dim embeddings.

## Local benchmark context from real Oghma data

Dataset:

- `15,341` production embeddings
- `4096` dimensions
- real Oghma chunks, not random vectors

Earlier benchmarks:

- PostgreSQL 18 + pgvector 0.8.2 exact scan: about `~230 ms` for current data.
- MariaDB 12.3.2 vector HNSW on same 4096-dim vectors: warm indexed search about `1.2-2 ms` server-side.
- Qdrant 1.18.2 local Docker on same data:
  - load via REST: `46.1s`, about `332 vectors/s`
  - storage: about `294 MB`
  - ANN ef64: server median `1.70 ms`, client median `6.08 ms`, p95 client `7.21 ms`, recall@10 `100%` on sampled real-vector queries
  - ANN ef128: server median `2.54 ms`, client median `6.89 ms`, p95 client `10.11 ms`, recall@10 `100%`
  - exact Qdrant: server median `9.33 ms`, client median `13.87 ms`

Caveat: recall test used sampled stored vectors as queries. Before production choice, also benchmark real query embeddings, folder/user filters, topK 10/20/50, hydration from Neon/Postgres, rerank, and concurrent load.

## Off-prem shortlist for 4096 dims

Given Cloudflare + Neon direction and 4096 dims fixed:

1. **Qdrant Cloud** — default recommendation.
   - Best balance for Oghma: supports 4096 dims, strong payload filtering, simple vector-index sidecar model, low platform opinion, easy migration from local Qdrant benchmark.
   - Architecture: Neon Postgres is truth; Qdrant Cloud is derived vector index.
2. **Pinecone** — best polished SaaS fallback.
   - Good if the priority is least ops and managed UX.
   - Watch namespace/filter design and usage-based cost surprises.
3. **Weaviate Cloud** — good if hybrid lexical+vector search/platform features become central.
   - More opinionated/schema/platform surface; some features may duplicate Oghma app logic.
4. **Zilliz Cloud/Milvus** — best for very large scale.
   - Strong at enterprise/massive vector workloads, but likely overkill early.

## Recommended architecture

```text
Cloudflare: app/API/frontend/R2/AI Gateway/etc.
Neon Postgres: users, notes, folders, chunks, jobs, auth, billing, canonical metadata.
Qdrant Cloud or other vector SaaS: chunk_id -> 4096-dim vector plus coarse payload.
```

Retrieval path:

```text
query embed -> vector DB topK chunk_ids -> Neon fetch + permissions/folder checks -> rerank -> answer
```

Security/correctness rule:

- Vector DB suggests candidates.
- Postgres/Neon remains the source of truth and performs final folder/permission/source-text hydration checks.
- Do not let vector DB payload become the sole authority for ACLs/billing/visibility.

## Reporting preference from this session

For Semyon, avoid long walls of text on architecture decisions. Give:

1. a one-line verdict,
2. a ranked shortlist,
3. the key blocker/tradeoff,
4. the next benchmark/action.

Only expand if he asks for detail.
