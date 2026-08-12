# Standalone architecture/demo decks and rendered-diagram galleries

Use this when building a temporary local HTML/Slidev/React artifact to present a project, especially for interview/demo walkthroughs.

## Target shape

- Clarify whether the user wants a product/site clone or a technical architecture demo. If they say architecture demo, bias toward system diagrams, data flow, ERDs, worker/deployment paths, and short code snippets; avoid marketing-site copy and product-tour slides.
- Prefer a short table of contents over “interview routing” language unless the user explicitly asks for routes. Keep it skimmable.
- For interview decks, reduce reading burden: one idea per slide, short labels, small captions, and optional appendix/reference material rather than dense main slides.
- Watch for bottom clipping. Use conservative image heights, reduce per-slide prose, and avoid stacking large diagrams plus paragraphs.

## Rendered assets and static serving

- For Slidev static builds, put images/SVGs referenced as absolute paths under `public/` (e.g. `public/diagrams/rendered/foo.svg`) so `dist/diagrams/rendered/foo.svg` exists after build. Do not rely only on source-side `diagrams/` folders.
- Verify with direct HTTP checks for the deck and representative assets, e.g. `curl -fsS http://127.0.0.1:<port>/diagrams/rendered/system.svg`.
- If using Mermaid CLI, keep the `.mmd` source next to rendered SVG/PNG and surface source links only when useful.

## Interactive diagram controls

- A mouse-following pointer should be off by default unless the user asks otherwise. Provide a visible toolbar toggle.
- For zoom/pan components: drag to pan, wheel/buttons to zoom, reset button, pointer toggle. Avoid keyboard-only activation for controls the user expects to follow the mouse.

## Code and live demos

- Prefer controlled “live walkthrough” components for interview reliability: clickable steps, active nodes, a tiny code excerpt, and one talk-track sentence.
- If adding code snippets, choose snippets that prove architecture: worker row locking, vector-store boundary, auth/rate-limit/request shaping, schema contract tests.
- Keep real backend demos optional; a deterministic local deck is safer under interview pressure.

## Deployment diagrams

- Include local quality gates before GitHub/CI when present: Husky pre-commit, pre-push/final local checks, lint/test/build/schema checks, then GitHub/webhook/CI/deploy.
- Do not invent a concrete hook file if it does not exist. Label it as “pre-push / final local gate” unless the repo has a tracked pre-push hook.
