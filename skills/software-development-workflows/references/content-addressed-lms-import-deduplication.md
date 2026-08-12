# Content-addressed LMS import deduplication

Use for Canvas/LMS file import systems where repeated course files make OCR, extraction, embedding, storage, or GPU spend expensive.

## Core boundary

A matching SHA-256 proves byte equality, **not permission to reuse another user's data**. Do not build a global cross-user cache by default.

Adopt reuse scopes in order:

1. **Per-user cache** — safe default; handles duplicate file IDs/references, repeated imports, and re-uploads.
2. **Explicit course-material corpus** — only for institution/domain + course-scoped, official files whose provenance is known and whose distribution is permitted.
3. **Explicit sharing/collaboration** — a recipient obtains a logical document reference through a share ACL; annotations remain private unless collaborative annotations are deliberately enabled.

Never let the cache include Canvas submissions, personal uploads, feedback, rubric material, or ambiguous files in a shared course corpus.

## Data model

Separate data layers rather than attaching ownership directly to an S3/RustFS path:

```text
document_blobs
  id, sha256, storage_key, mime_type, byte_size, lifecycle_state

document_derivatives
  id, blob_id, extractor/version, embedding model, chunker version,
  quality state, extracted content

document_chunks
  derivative_id, ordinal, text, vector state

note_documents
  id, note_id, attachment_id, blob_id, derivative_id, user_id,
  source_type, access_scope, lifecycle state

pdf_annotations
  user_id, note_document_id/attachment_id, annotation payload
```

A user-visible note and attachment are logical projections; the raw blob and its reusable derivation may be shared only through an authorized `note_documents` reference.

## Authorization invariants

- Authorize downloads, ranges, exports, presigned URLs, and derived-content reads by joining authenticated user → active logical reference → blob/derivative.
- Never authorize by SHA, storage key, cache ID, or a direct shared URL.
- Keep shared object storage private. A raw object key must not be a bearer capability.
- Keep retrieval user-scoped even when vectors were generated from reusable derivatives. Do not let cache/sentinel vectors appear in ordinary search.
- Do not expose cache-hit status, source user, shared key, or cache ID to clients; cache timing can otherwise disclose that a predictable document exists.

## Build state machine

Avoid holding a pooled PostgreSQL session advisory lock around download/OCR/Marker/Qdrant work. It can lock one session while the work/unlock run on others, leak locks, and block future imports.

Use an atomic DB claim/lease instead:

```text
building -> ready
        -> failed
lease_owner, lease_expires_at, attempt_count
```

1. Atomically create or claim a cache row for `(scope, digest, derivative-version)`.
2. Upload/store the immutable blob if needed.
3. Produce derivatives outside the DB transaction.
4. Record chunk rows and expected vector count transactionally.
5. Write/copy vectors outside that transaction.
6. Validate every expected vector exists, then promote to `ready` + `replayable`.
7. Repair expired leases/partial vectorization idempotently.

Do not mark a cache ready if a Qdrant fetch/copy is incomplete. Add chunk ordinals; timestamp ordering is not a durable ordering contract.

## Extraction quality and assets

- Store extractor, chunker, embedding model, and quality/version metadata with the derivative.
- A fallback PDF parse followed by Marker/GPU enrichment must refresh or replace the derivative before it is reusable. Do not cache degraded output permanently while a later job improves only the first user's note.
- Note-local assets inside extracted Markdown make it non-replayable. Either store assets in a shared authorized derivative namespace or defer caching until output has no user/note-local references.

## Lifecycle / deletion

Per-note trash, permanent deletion, account deletion, and failed-import rollback must remove only that user's logical projection, annotations, chunks, and retrieval vectors.

They must **not** delete a shared blob merely because one attachment references its key. Use a dedicated cache GC:

1. Find blobs with no active logical references after a grace period.
2. Re-check/reclaim them atomically.
3. Delete derivatives/vectors/blob only when still unreferenced.
4. Verify a cache hit's object exists before publishing a new reference; restore/rebuild if necessary.

## Test matrix

Use integration tests/fault injection, not helper-only tests:

- Same bytes, same user, different Canvas IDs → one extraction/embedding.
- Same official file in authorized course scope → safe reuse; no OCR/embed call on warm hit.
- Same bytes in different users without entitlement → no cross-tenant reuse.
- Submission/private attachment → never enters a course-shared cache.
- Two concurrent imports of same digest → exactly one build; expired lease recovers.
- Delete one user's logical reference → another user's file remains downloadable/searchable.
- Missing or partial vectors → cache not replayable or normal embedding fallback runs.
- Fallback extraction then Marker completion → cache refreshes to final version.
- Direct key, cache ID, and SHA requests cannot retrieve content without a current logical reference.

## Cost expectations

A hash computed after download cannot avoid the Canvas download itself. A warm cache can avoid extraction/OCR/Marker and embedding generation, but will still incur discovery calls, data transfer, logical-note creation, authorization, and often user-scoped vector/chunk projection writes. Instrument cache hit/miss, bytes saved, extraction avoided, embedding avoided, vector expected/copied, and elapsed time separately.
