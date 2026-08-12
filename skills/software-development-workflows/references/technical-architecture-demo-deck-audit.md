# Technical architecture demo deck audit notes

Use these notes when building or revising architecture/demo decks from a real repo, especially when the project has migrated through several infrastructure generations.

## Workflow pattern

1. Keep presentation work separate from any parallel personal/anecdote/storytelling agent. Technical deck changes should only touch deck/assets/code evidence.
2. Before finalizing diagrams, audit both:
   - **Current implementation**: routes, workers, storage adapters, auth, DB migrations, CI/deploy files, tests.
   - **History/future docs**: `git log`, migration commits, infrastructure docs, roadmap/target hosting docs.
3. If the user asks for technical correctness across past/present/future, delegate at least two read-only audits:
   - one current-state implementation audit,
   - one git-history/docs evolution audit.
4. Reconcile findings before editing diagrams. Label nodes as **past**, **present/current**, **future/target**, **historical/fallback**, **external**, or **open decision**.
5. Re-render Mermaid assets and verify the built deck serves every SVG URL over HTTP, not just that Slidev builds.

## Deck shape that worked better

- Prefer a normal **Table of contents** over an “interview routing map” unless the user explicitly asks for routing.
- Keep it short enough to read live: one idea per slide, no “improvements”/closing fluff unless asked.
- For Slidev, preserve presenter usefulness but avoid bottom clipping:
  - reduce slide padding before adding scroll,
  - keep diagram heights conservative,
  - shrink dense interactive components,
  - use fewer bullets and shorter captions.
- Pointer/laser should be **off by default** with a visible toolbar toggle. Do not require keyboard focus for pointer behavior.
- Do not create a product-site clone. For architecture interviews/exams, use system/data/deployment diagrams, ERDs, and a few high-value code snippets.

## Accuracy pitfalls from OghmaNotes-style projects

- Do not collapse provider-compatible APIs into one provider label. “S3-compatible object storage” may mean AWS S3 historically, RustFS currently, or R2 as a target.
- Keep AWS-native framing honest: say “AWS SDK/S3-compatible semantics” if that is the stable interface, and separately label the actual provider per stage.
- If vectors moved from Postgres/pgvector to Qdrant, current ERDs should not show `app.embeddings`; show Postgres chunk metadata plus Qdrant vector storage.
- Future-state docs can contradict current implementation. If target docs say Neon pgvector but current code uses Qdrant, label the future vector backend as an open decision rather than choosing one silently.
- MCP/AI chat tooling often deserves its own diagram, not a tiny note: include AI SDK client, internal MCP route, tool budget/guardrails, OAuth/session/account links, and external LLM/embedding providers.
- Include local quality gates in deployment diagrams if present: Husky pre-commit, pre-push/final local gate, Jenkins/GitHub hooks. Do not invent a concrete hook file if only a generic/final gate exists.

## Verification checklist

- [ ] Mermaid source updated for all affected diagrams.
- [ ] SVG/PNG rendered successfully.
- [ ] Assets copied under `public/` for Slidev static builds if referenced as `/diagrams/...`.
- [ ] `npm run build` or equivalent deck build passes.
- [ ] Target device/server returns HTTP 200 for the deck and representative SVGs.
- [ ] Claims in slides match repo evidence and are stage-labelled when historical/future.
