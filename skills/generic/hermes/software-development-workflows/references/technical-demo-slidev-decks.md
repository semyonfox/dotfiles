# Technical demo decks and diagram galleries

Session-derived guidance for turning repo diagrams/code into an interview/demo artifact.

## When to use

Use this when Semyon asks for an architecture/demo presentation, rendered diagrams, or a browser-opened deck for an interview/examiner walkthrough.

## Workflow

1. **Decide the surface before editing**
   - If the target is a generated artifact/deck, edit that artifact, not the production app.
   - Keep source files in a copied demo directory when the user is iterating presentation style fast.

2. **Prefer Slidev for technical decks when requested**
   - Slidev is Vue-based and works well for code-reveal slides, custom Vue components, presenter mode, and technical walkthroughs.
   - A static build can be served locally with a simple HTTP server for reliability.
   - Put static assets under `public/` so Slidev’s static build serves them at stable `/...` URLs; do not rely only on arbitrary source folders.

3. **Render diagrams, don’t fake them**
   - Use Mermaid source (`.mmd`) and render to SVG/PNG with Mermaid CLI.
   - Verify each SVG URL returns 200 from the final served deck, not just that files exist locally.
   - If SVGs appear broken in Slidev, check whether they were copied to `public/` before build.

4. **Keep interview decks concise**
   - The deck should not clone the product website or become a product tour unless asked.
   - Prefer a short table of contents over “interview routing” language.
   - Avoid “improvements/future work” and closing filler slides unless explicitly requested.
   - If the user says content is missing at the bottom, reduce slide padding, diagram heights, and component heights rather than adding scroll-heavy content.

5. **Use interactive diagrams carefully**
   - Pan/zoom can help large SVGs, but pointer/laser should be **off by default**; provide a visible toolbar toggle.
   - Avoid keyboard-focus-only controls for presentation interaction.
   - For a “live” feel, a controlled Vue component that steps through architecture/code flow is safer than depending on live backend calls during an interview.

6. **Diagram content checklist for OghmaNotes-like architecture demos**
   - Show external embedding API explicitly; do not imply Qdrant creates embeddings.
   - Label object storage generically as S3-compatible, with AWS S3 primary/natural and R2/RustFS as deployment-stage variants where relevant.
   - Include AI chat tooling/MCP when present: AI SDK MCP client, internal MCP token, `/api/mcp/canvas`, Canvas MCP tools, tool-call budget, SSE streaming.
   - Include OAuth/session/account links where authentication/account integration matters.
   - Include local quality gates in deployment: Husky pre-commit, tests/lint/infra checks, pre-push/final local gate if present or used.

## Verification

- `npm run build` for the deck.
- Serve the final `dist/` and `curl` the deck URL plus representative SVG URLs.
- Re-open in the target browser/device after restarting the service/server.
- Grep the deck/diagram sources for the user-requested concepts after changes (e.g. `OAuth`, `External embedding API`, `S3-compatible`).
