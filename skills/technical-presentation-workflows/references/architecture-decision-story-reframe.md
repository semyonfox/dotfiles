# Architecture decision story reframe — Oghma Slidev lesson

Use this when a technical deck starts sounding like an interview pitch, self-promotion, or generic SRE keyword checklist instead of a real architecture walkthrough.

## User correction captured

Semyon pushed back that the OghmaNotes deck felt too much like:

- “look at me, this is for an interview”
- generic proof of skill
- an SRE/interview framing pasted onto the project

He wanted more:

- walkthrough of the architecture
- decisions and tradeoffs
- stories from the system itself
- why each boundary exists
- what Eidhne/the project has been through, not “please hire me” energy

## Reframe pattern

Convert visible slide labels from career/interview language to system/decision language:

- `Interview story` → `System story`
- `Current system` → `Current architecture`
- `Async ingestion path` → `Ingestion decision`
- `Safe worker claim` → `Worker claim detail`
- `Deployment and quality gates` → `Release path`
- `What I would harden next` → `Reliability roadmap`

Change the title/subtitle from reliability résumé framing to architecture framing:

- `OghmaNotes reliability walkthrough` → `OghmaNotes architecture decisions`
- `Reliability-focused walkthrough...` → `How a notes workspace becomes a reliable system.`

## Speaker-notes cleanup

Search and remove these from visible slides and notes unless the user explicitly asks for interview prep:

- `interview`
- `STAR`
- `pitch`
- `hire`
- `theatre`
- role/company-specific closing lines
- “this shows how I think” as the primary story

Replace with architecture talk tracks:

- problem pressure
- boundary choice
- consequence
- tradeoff
- failure mode
- implementation proof
- what becomes observable/recoverable

## Better narrative shape

Main flow should sound like:

1. This product sounds simple, but notes/files/imports/chat/retrieval create different failure boundaries.
2. The core decision is to keep user-facing paths small and move expensive work behind jobs.
3. Data ownership is explicit: Postgres for relational truth, object storage for blobs, Qdrant for vectors, providers as dependencies.
4. The ingestion boundary exists because upload should not depend on parsing, chunking, embedding, external providers, or vector writes.
5. The worker-claim code is implementation proof for the boundary, not a flex.
6. Release path is part of the architecture because app/worker versions, migrations, queue behaviour, and runtime errors interact.
7. Reliability roadmap is the next engineering chapter, not a job-interview closer.

## Verification checklist

Before handing back:

- Search `slides.md` for interview/pitch vocabulary and remove it if the task is an architecture walkthrough.
- Visually inspect at least slides 1–7 after the reframe; wording changes can alter wrapping and card height.
- Keep appendix as back-pocket evidence, not the main story.
