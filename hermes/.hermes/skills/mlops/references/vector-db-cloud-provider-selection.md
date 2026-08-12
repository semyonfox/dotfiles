# Cloud vector DB selection for high-dimensional RAG

Use when choosing a managed vector backend for an app that is moving off-prem/cloud and already has high-dimensional embeddings.

## Durable lessons from OghmaNotes

Context:

- Canonical DB is moving toward managed Postgres such as Neon.
- Hosting/storage are moving toward Cloudflare where practical.
- Existing embeddings are 4096-dimensional and the user explicitly wanted to keep dimensions unchanged.
- Current pgvector HNSW limits still matter on managed Postgres: `vector` indexes up to 2000 dims, `halfvec` up to 4000 dims, `bit` much higher. A 4096-dim `vector` column cannot get a normal HNSW pgvector index.
- Cloudflare Vectorize docs currently list max vector dimensions as 1536, so it is not a fit for unchanged 4096-dim embeddings.

## Recommendation shape

When dimensions must stay 4096, compare managed vector DBs rather than recommending a full relational DB migration:

1. **Qdrant Cloud** — default first pick for Oghma-shaped workloads.
   - Supports high dimensions; Qdrant docs list dense vectors up to 65,535 dims.
   - Good payload filtering and simple `Postgres = source of truth, Qdrant = derived index` architecture.
   - Local benchmark on real Oghma data was strong: 15,362 vectors × 4096 dims, Qdrant 1.18.2, ANN server median ~1.45-3.03 ms depending `hnsw_ef`, client median ~5.83-7.62 ms, recall@10 ~99.2-99.6% against NumPy exact.
2. **Pinecone** — good managed/SaaS fallback if ease-of-ops beats tunability.
   - Watch namespace/filter design for tenant/folder scoping and cost.
3. **Weaviate Cloud** — consider if hybrid BM25 + vector/search-platform features become central.
   - More opinionated; may duplicate app-owned RAG/schema logic.
4. **Zilliz Cloud / Milvus** — consider for very large scale or enterprise vector workloads.
   - Powerful but heavier than Oghma needs early on.

## Architecture pattern

Keep canonical data in Postgres/Neon:

- users
- notes
- folders
- chunks
- auth/session/billing/job state
- source text and permissions

Vector DB stores derived index data only:

- stable chunk/vector ID
- 4096-dim vector
- coarse payload fields such as `user_id`, `workspace_id`, `note_id`, `folder_id`, `embedding_model`, `deleted`

Query path:

```text
embed query -> vector DB topK chunk IDs -> Postgres/Neon hydrate + final permission/folder checks -> rerank/answer
```

Security rule: the vector DB can narrow candidates, but Postgres remains authoritative for permissions and source text.

## Benchmark pattern used for Oghma

- Export real `app.embeddings` from PG18, not synthetic vectors.
- Sample deterministic query vectors with seed 42.
- Compute ground truth top-10 using NumPy cosine over all vectors.
- For Qdrant, test ANN `hnsw_ef` values such as 64/128/256 plus exact query mode.
- Record both server-reported time and client wall time.
- Compare against PG exact scan using `EXPLAIN (ANALYZE, TIMING OFF, FORMAT JSON)`.
- Clean temporary containers and large TSV exports; keep small `summary.json` and scripts.

## Reporting style for this user

For Semyon, avoid giant decision essays unless explicitly asked. Start with the decision, then give short bullets and only the numbers that change the recommendation. If he asks for a summary, compress aggressively.
