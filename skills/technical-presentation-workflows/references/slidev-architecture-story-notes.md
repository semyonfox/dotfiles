# Slidev architecture story + speaker-notes pattern

Use this after a technical deck starts feeling like disconnected architecture slides, an interview pitch, or a generic skill demo.

## User correction captured

Semyon pushed back that the deck needed:

- architecture for the interview as the main value
- a little background and product story, but not visible-slide bloat
- issues/failure modes available to allude to if already discussed
- deeper detail available in speaker notes if the conversation does not naturally cover it
- less "story slapped in" energy; the story should make later architecture slides feel inevitable

## Deck shape that worked

Keep visible slides short and architecture-first. Move elaboration into speaker notes as optional branches.

Main visible narrative spine:

1. **The story** — real coursework creates product/system pressure.
2. **Architecture response** — split into intent, work, and memory.
3. **Ingestion boundary** — user sees acceptance/status; worker does slow work; operator sees queue pressure.
4. **Worker claim** — implementation proof for safe background processing.
5. **Operating the story** — deploy/release/observe keeps the architecture true as code changes.
6. **Next chapter** — observe, recover, protect, prove.

Good visible thread line:

> capture intent → ingest safely → retrieve with scope → operate the system

## Speaker-notes convention

For each main architecture slide, add structured optional notes:

- `Core point:` or `Core 20-second version:`
- `If time is short:`
- `If they ask why not simpler:`
- `If they ask for current technical facts:`
- `Optional side story if there is room:`
- `Background issue to mention if relevant:`
- `If asked what is unfinished:`
- `If they ask what can fail:`
- `If they ask where you would start:`

This lets Semyon keep the visible deck lean while having interview-ready depth without memorising a monologue.

## Content guidance

Prefer product pressure → architecture boundary → operational consequence.

Example core story:

> OghmaNotes starts as a study workspace, but real coursework makes it architectural: uploads, Canvas imports, retrieval, AI providers, and user trust all fail differently. So the system captures intent quickly, moves fragile work into recoverable background paths, separates data ownership, and makes important boundaries observable.

For Oghma-style decks, keep Eidhne/user stories as optional colour, not the main visible pitch. Use them to explain why a boundary exists, not to replace architecture.

## Pitfalls

- Do not make the story a standalone intro pasted before unrelated architecture slides.
- Do not show long background paragraphs on the slide; put them in notes.
- Do not turn reliability roadmap slides into generic hardening checklists. Tie each item back to the architecture boundary it protects.
- Do not treat CI/deploy slides as trophy slides. Frame them as how app routes, workers, migrations, queues, and dependencies stay aligned while changing.
- Do not over-index on interview language. The interview benefits from credible architecture; it should not sound like a job pitch.

## Verification

After rewriting copy:

- run the build
- browser-check the main slides, especially card rows and code slides
- search for stale pitch/interview vocabulary if the deck should be architecture-first
- confirm speaker notes contain optional branches, not another full script to read verbatim
