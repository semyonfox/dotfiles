# Slidev interview deck cleanup pattern

Use when cleaning a Slidev technical/project deck for an interview demo, especially SRE/service-resiliency framing.

## Presentation shape

Keep the visible slideshow short and slideworthy. A good 6–8 minute technical interview flow is:

1. Title / one-line purpose.
2. Interview story: problem, system, SRE angle.
3. Current system diagram.
4. Past/present/future architecture evolution when the implementation has changed.
5. Deployment / quality gates.
6. One interactive or concrete workflow slide.
7. One bounded feature boundary slide, e.g. RAG/data/tooling.
8. Data ownership / architecture decision.
9. One code proof slide only if it demonstrates an engineering property.
10. “What I would harden next” mapped to observability/recovery/protection/tests.

Avoid product-tour tables of contents, long visible explanatory paragraphs, or multiple code slides unless specifically asked.

## Speaker notes

For Slidev, move talk tracks into presenter notes using HTML comments under each slide:

```md
# Visible slide title

Short visible content only.

<!--
Talk track:
- what to say
- what to skip unless asked
- SRE/reliability angle
-->
```

This keeps the main slide clean while making Presenter Mode useful. Do not dump paragraphs into visible `<div class="small">` blocks just because they are “notes”.

## SRE interview framing

For Genesys/service-resiliency style interviews, frame projects around production thinking:

- request rate, error rate, p95/p99 latency
- queue depth and worker failures
- dependency failures and timeouts
- idempotency, retries/backoff, dead-letter paths
- deployment/version changes, rollback, health checks
- structured logs, runbooks, and RCA-ready evidence
- generic public errors with internal detail in logs/metrics

Useful closing line: “The project is useful as a product, but for this interview the important part is that it gave me real failure modes to reason about.”

## Slidev diagram fit / clipping pattern

Mermaid SVGs can still clip at the edge after rendering. Combine these fixes:

- Render Mermaid to SVG/PNG artifacts rather than relying only on live Mermaid.
- Add a `viewBox` padding pass for rendered SVGs so strokes/text near the outer bounds are not shaved off.
- In custom SVG viewer components, parse the SVG `viewBox`, set explicit image width/height, compute a fit-to-frame scale, and leave a real gutter (not just a few pixels). A margin around 80–100px worked better than 16px for wide architecture diagrams.
- Verify with a browser screenshot/vision check; accessibility-tree text is not enough for deck QA.

## Semyon style preference for portfolio-themed decks

For Oghma/portfolio-aligned decks:

- background `#0b0b0b`
- surface cards `#151515`
- border `#252525` or `rgba(240,240,240,.06)`
- fox orange `#e8702a`
- Inter, heavy headings, no negative letter spacing
- bento cards with subtle borders and small orange markers/dots
- avoid chunky orange left bars unless he explicitly asks for that version
- avoid AI-SaaS-looking decorative accents; keep it credible and technical
