# Vector database benchmarking notes

Use this reference when comparing vector storage/search options for AI/RAG applications, especially when the choice affects the primary relational database.

## Benchmark shape

1. Use the application's real embeddings when possible, not random vectors. Real embeddings expose actual dimensionality, norms, storage size, and recall behaviour.
2. Record exact versions for each engine and extension/image, e.g. PostgreSQL, pgvector, MariaDB, Qdrant, etc.
3. Compare at least these cases:
   - exact scan with no ANN index
   - ANN/indexed search where supported
   - load/import time
   - index build time
   - table/index storage size
   - warm and cold-ish query latency
   - recall/overlap against exact top-k for a sample of query vectors
4. Test the exact query pattern that production will use. Some engines only use vector indexes for narrow forms such as `ORDER BY distance(column, query) ASC LIMIT k`.
5. Distinguish relational DB performance from vector-index compatibility. A relational migration is often the wrong fix for a vector search constraint.

## Metrics to report

- Dataset: rows/chunks, dimensions, source, export size.
- Versions: DB/server, vector extension, Docker image tags.
- Storage: table size before/after index, staging/import scratch if relevant.
- Load: bulk load/copy time and vector conversion time.
- Exact search: median/range over multiple runs for cosine, L2, and inner product if supported.
- Indexed search: build time, query plan confirming index use, first/warm query latency.
- Recall: top-k overlap between exact and ANN results across multiple query vectors.
- Operational cost: migration effort, backup/restore changes, permissions/deletes/sync risks.

## Pgvector dimensionality pitfalls

As of pgvector 0.8.x:

- `vector` HNSW/IVFFlat indexes support up to 2000 dimensions.
- `halfvec` indexes support up to 4000 dimensions.
- binary quantization / `bit` indexes can support much larger dimensions.

For embeddings above those limits, test alternatives before recommending a full relational DB migration:

- use a lower-dimensional embedding model
- index a reduced/projection/subvector representation
- use half precision if within limit
- use binary quantization for retrieval plus re-rank exact vectors
- split vector search into a dedicated vector store behind an abstraction

## Distance metrics quick reference

- Cosine similarity measures direction/angle: `dot(a,b) / (|a||b|)`. Cosine distance is commonly `1 - cosine_similarity`. Good default for text embeddings.
- Euclidean/L2 measures raw geometric distance: `sqrt(sum((a-b)^2))`. If vectors are normalized, L2 and cosine produce equivalent rankings.
- Dot product / inner product measures alignment and magnitude: `sum(a*b)`. If vectors are normalized, dot product and cosine rank equivalently. Otherwise magnitude changes the ranking.
- "Sine distance" is not a standard production vector DB metric; clarify whether the user means cosine, angular distance, or L2.

## Reporting stance

When advising a product/database decision, give the decision tree explicitly:

- If current high-dimensional embeddings must remain in one relational DB and one engine can index them while another cannot, say so directly.
- If changing embedding dimensionality or vector architecture avoids a full relational migration, quantify that path too.
- Prefer `source of truth DB + replaceable VectorStore abstraction` when the vector backend may change later.
