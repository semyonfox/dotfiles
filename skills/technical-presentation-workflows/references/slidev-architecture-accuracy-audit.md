# Slidev architecture accuracy audit — Oghma lesson

Use this when an interview/demo deck describes a real project's current architecture, especially after migrations between providers or queue/storage systems.

## Trigger

The deck looked visually good but still had a credibility bug: it claimed the current ingestion worker proved safe concurrency via a Postgres `FOR UPDATE SKIP LOCKED` job-claim snippet, while the current repo actually uses BullMQ/Redis for queue delivery and a separate Node worker container. Postgres stores durable job/status/recovery state; the SQL polling worker was legacy/stale.

## Workflow

1. Do not trust the handover doc or previous slide text as source of truth.
2. Audit the canonical repo and infra docs before finalizing provider/runtime labels:
   - `AGENTS.md`
   - `README.md`
   - `infra/HOMELAB.md`
   - `infra/TARGET_HOSTING.md`
   - `infra/AWS_INFRASTRUCTURE.md`
   - relevant runtime code: queue facade, worker entrypoint, upload/import routes, RAG/vector code
   - supporting server-stack files when infrastructure claims matter
3. Separate architecture tense explicitly:
   - retired/historical
   - current/live
   - target/future/trial
4. Patch both visible slides and speaker notes. Notes should contain the exact caveat so Semyon can answer if challenged.
5. Patch appendix diagrams too; stale diagrams are worse than no diagrams because interviewers will probe them.
6. Re-render changed Mermaid diagrams, copy them to `public/diagrams/rendered`, run SVG padding, build, and visually inspect affected slides.

## Oghma-specific facts verified in this session

- Old/retired: AWS app stack with S3/SQS/ECS-era pieces and older pgvector/app.embeddings style vector storage.
- Current: homelab Docker/Jenkins behind Cloudflare tunnels.
- Current stateful pieces: Postgres, Redis/BullMQ, RustFS S3-compatible object storage, Qdrant.
- Current worker path: API routes create durable Postgres job/status records, enqueue to BullMQ/Redis, and a separate Node worker container consumes queues such as `canvas-import` / `extract-retry`.
- Postgres role: durable truth/status/recovery, not the primary queue delivery mechanism.
- `FOR UPDATE SKIP LOCKED` exists in older/stale worker code and as a current race/safety guard in a Canvas completion path, but should not be presented as the main current ingestion queue mechanism.
- Future/target: gradual Cloudflare edge/email/R2 and possibly Cloudflare Queues, plus Neon/Postgres-style target. Workers/OpenNext is a trial, not current truth.
- RAG/scoped retrieval proof: normalize requested note/folder scope, filter Qdrant by `user_id` and optional `document_id`, join chunks through Postgres with user filtering, then call the external LLM.
- Canvas orphan recovery is scoped: current code can reclaim queued/discovering Canvas import jobs; do not imply generic uploaded-file `app.ingestion_jobs` orphan polling is live unless the current worker entrypoint proves it.

## Common fixes

- Replace vague/overclaiming observability language like “operator knows” with “operator can inspect logs, health checks, queue state, job status, worker failures, and rollback points.”
- Put unfinished SLI/alerting work in the next-hardening slide, not the current-state slide.
- Rewrite generic “next chapter” quadrants into a concrete prioritized plan: oldest job age, failure count, retry count, provider latency, failed-job inspection, replay/DLQ tooling, scoped retrieval checks, failure-mode tests.
- Remove stale code proof if it proves an old architecture. Use the current worker/queue code instead.
- Audit appendix diagrams with the same strictness as main slides: Canvas/import diagrams must show BullMQ/Redis as dispatch and Postgres rows as status/recovery; ERDs must reflect current `chunks(document_id,user_id,text,...)`, FSRS quiz-card fields (`stability`, `difficulty`, `scheduled_days`, timestamp `due`), and current `quiz_questions(question_text, question_type, bloom_level, correct_answer)` rather than old SM-2/`chunk_index`/`question` shorthand.

## Mermaid rendering note

If `mmdc` fails due Chromium sandboxing on Linux, use a temporary Puppeteer config with `--no-sandbox` / `--disable-setuid-sandbox` for rendering only, then continue with normal build/visual QA. Capture the fix pattern, not the transient failure.
