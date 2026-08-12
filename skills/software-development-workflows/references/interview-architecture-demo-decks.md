# Interview architecture demo decks

Use when Semyon asks for a technical demo/presentation deck for an interview, examiner demo, or architecture walkthrough.

## Lessons from OghmaNotes Slidev deck iteration

- Clarify the surface: if the user says this is an “architecture demo”, do not make it a product/marketing tour or clone the public site. Make the deck about system boundaries, data flow, database design, worker behavior, deployment, and tested engineering decisions.
- Slidev is a good fit for this class because it is Vue-based and supports Markdown slides, Vue components, code-step highlighting, presenter/drawing tools, and static builds.
- For static Slidev builds, put referenced files under `public/` (for example `public/diagrams/rendered/*.svg`) when slides/components reference `/diagrams/...`. Referencing copied assets outside `public/` can work in dev but break after `slidev build`.
- If diagrams need pan/zoom/pointer interaction, add a small Vue component rather than relying only on browser zoom. Good controls: drag to pan, mouse wheel to zoom, toolbar buttons for `+`, `-`, pointer on/off, reset. Make the pointer follow the mouse by default; do not require keyboard focus or hidden hotkeys for basic use.
- Add an interactive “architecture walkthrough” component for interview depth: clickable steps that show active nodes, a real code snippet, and a short talk track. This is safer and more reliable than a fragile live backend demo, while still feeling live.
- Keep a route map slide: “If they ask X, go to slides Y–Z.” Also include the same route cheat sheet in the chat handoff.

## Recommended shape

1. Title: technical positioning, not product copy.
2. Route map: architecture / RAG / database / code / operations.
3. System architecture diagram with pan/zoom.
4. Interactive architecture walkthrough.
5. RAG / Canvas / deployment diagrams.
6. Current ERD and focused ERDs.
7. Code slides with actual snippets from the repo:
   - worker job claim / concurrency (`FOR UPDATE SKIP LOCKED`)
   - vector store boundary (Qdrant collection/config/payload indexes)
   - API route shape (auth, rate limits, scoped RAG, streaming)
   - schema contract tests / migration guardrails
8. Future-improvements slide: observability, RAG evaluation, compliance/OAuth/LTI.

## Verification

- Run `npm run build` for the deck.
- Serve the static build and `curl` the deck root.
- `curl` every SVG URL referenced by interactive components; require HTTP 200.
- Restart/open the deck on the target device and report the local URL and source path.
