# Slidev architecture story + zoomable SVG lesson

Session lesson from the OghmaNotes architecture deck.

## User corrections

Semyon pushed back on two things:

1. The deck still felt like an interview/self-promotion frame rather than a walkthrough of the architecture and the stories Eidhne/Oghma has.
2. After cleanup, the SVG viewer became too static; he explicitly wanted the zoomable SVGs back.
3. The "story" slide initially felt slapped in: labels were changed, but the rest of the deck did not yet follow a concrete narrative spine.

## Better architecture narrative spine

For Oghma-style project decks, do not just rename slides to sound architectural. Make the entire main flow follow one product/system story:

> OghmaNotes starts as a notes app, but becomes interesting when real coursework enters the system: PDFs, notes, Canvas material, retrieval, AI calls, and user trust all fail differently. The architecture exists to accept messy user intent quickly, push expensive/fragile work into recoverable background jobs, keep data ownership explicit, and make the system operable.

A stronger 7-slide flow:

1. **Architecture story** — simple notes app meets real coursework pressure.
2. **The story** — user pressure, system pressure, architecture answer.
3. **Architecture response** — intent, work, memory.
4. **Ingestion boundary** — what the user sees, what the worker does, what the operator knows.
5. **Worker claim** — implementation proof that keeps ingestion honest when workers scale.
6. **Operating the story** — deploy/change path as part of the architecture.
7. **Next chapter** — observe/recover/protect/prove as continuation, not generic checklist.

Concrete wording that worked:

- Title: `OghmaNotes architecture story`
- Subtitle: `When a notes app has to survive real coursework.`
- Thread line: `upload/import → ingest safely → retrieve with scope → operate the system.`

## Avoid the slapped-in story smell

A slide labelled "System story" is not enough. The following slides must answer it. Tie each technical section back to the same pressure:

- Upload/import creates intent.
- Ingestion performs slow/fragile work away from the request.
- Retrieval must remain scoped to owned material.
- Data stores have ownership boundaries.
- Worker claim logic proves concurrency discipline.
- Release/observability keeps the architecture true while it changes.

If the deck still feels abstract, add one concrete user/Eidhne vignette before adding more architecture:

> Eidhne imports a module from Canvas before studying. Upload succeeds quickly, ingestion runs in the background, retrieval only uses scoped material, and failures become visible instead of silently breaking trust.

## Clean zoomable SVG pattern

For presentation diagrams, keep zoom explicit and visible, not hidden magic:

- Provide small visible controls: `− / 100% / +`.
- Reset via the percentage button.
- Limit zoom range, e.g. `100% → 300%`.
- Allow drag/pan only after zooming in.
- Avoid accidental slide-navigation breakage: wheel zoom only with a deliberate modifier (`Alt`, `Ctrl`, or `Cmd`).
- Do not append cache-busting `?v=...` to SVG URLs unless debugging a stale asset; Semyon specifically asked to drop that.
- Preserve dark frame/background consistency and verify 100% plus zoomed views in browser.

## Verification checklist

After story or SVG changes:

- `npm run build`.
- Confirm hosted root and at least one SVG asset return `HTTP 200`.
- Browser-check slides 1–4 after wording changes; narrative rewrites often alter wrapping/card height.
- Browser-check an appendix diagram at 100% and zoomed in.
- Confirm SVG URLs are clean if the user complained about `?v` cache-busting.
