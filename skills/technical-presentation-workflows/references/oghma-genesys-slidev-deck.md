# OghmaNotes / Genesys SRE Slidev deck session notes

This reference captures a reusable pattern from the July 2026 OghmaNotes Genesys interview deck work.

## Context

Semyon wanted a Slidev deck for an OghmaNotes demo/architecture walkthrough for a Genesys Service Resiliency/SRE interview. He asked for small styling improvements inspired by his portfolio, explicitly with no gradients or obvious AI styling.

## Useful deck story

Core message:

> Production issues are not always code bugs. Sometimes the architecture does not match the platform constraints, and the fix is to redesign the flow so failure is visible, recoverable, and not blocking the user.

Strong lines:

- Local success does not prove production readiness.
- Not every job belongs in the web request path.
- Long work needs queues, workers, durable progress, retries, and visible failure states.

## Good deck structure

1. What the product is
2. High-level architecture
3. Production failure / platform constraint
4. Before: long-running request path
5. After: queue + worker + DB progress
6. Code path examples
7. Security/ownership boundary
8. Observability/logging
9. Deployment shape
10. What to harden next
11. SRE takeaways
12. Appendix / steerable references

## Styling palette used

- background: `#0b0b0b`
- surface: `#151515`
- panel: `#101010`
- border: `#252525`
- muted text: `#949494`
- dim text: `#6a6a6a`
- accent: `#e8702a`
- heading: `#f0f0f0`

## Slidev serving quirk

For Slidev v52 in this session, `--host` failed. Remote LAN serving worked with:

```bash
pnpm exec slidev --port 3030 --remote --bind 0.0.0.0
```

If native bindings/package state is stale after moving between environments, the practical fix was:

```bash
rm -rf node_modules
pnpm install
pnpm build
```

Do not encode this as “Slidev is broken”; it was a dependency state fix.

## Verification pattern

- Run `pnpm build`.
- Start Slidev or a static server.
- Open in browser.
- Visually inspect at least title, architecture diagram, and code slides.
- If Mermaid clips, simplify the diagram and constrain SVG height.
- If code clips, shorten snippets rather than shrinking text too far.
