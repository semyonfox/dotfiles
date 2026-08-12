# Slidev + Mermaid architecture decks

Use this when building or revising technical Slidev decks with Mermaid diagrams.

## Durable workflow

1. Keep the deck source editable (`slides.md`, Vue components, `.mmd` files) and render Mermaid to real SVG/PNG assets before presenting.
2. For large architecture diagrams, do **not** rely on raw `img` natural size for SVGs. SVG images often report misleading intrinsic dimensions in browsers. Fetch the SVG text, parse `viewBox`, set explicit CSS `width`/`height` from it, then fit-to-frame with scale + translation.
3. Default diagrams to **fit inside the visible frame**. Provide controls for `fit`, `100%`, zoom, and pan. A deck should never silently clip bottom/right edges at the default view.
4. Mermaid often renders strokes/text exactly on the `viewBox` edge. After rendering, pad SVG `viewBox` by a safe margin (for example 64–96px) and mark the file with a normal comment after the opening tag, not inside the `<svg ...>` attribute list.
5. Keep code blocks scrollable (`overflow: auto`) rather than hidden. Hidden code in slides looks clean but can silently remove evidence.
6. Build and visually inspect the actual served deck, not only the source. Check at least: cover, table of contents/cards, one wide architecture diagram, and one code-heavy slide.

## Style lessons from Semyon

- Avoid generic “AI deck” styling unless explicitly requested. In this session, chunky orange left borders initially looked too generated.
- If matching Semyon's portfolio, use a dark bento style:
  - background `#0b0b0b`
  - surface `#151515`
  - border `#252525` / `rgba(240,240,240,0.06)`
  - muted `#949494`, dim `#6a6a6a`, heading `#f0f0f0`
  - fox orange `#e8702a`, used sparingly for dots, tiny labels, active states, and subtle 2px accents.
- Portfolio-style cards should be subtle bento cards with small orange markers/dots, not large orange sidebars.
- Inter with heavy headings and zero letter spacing matches the portfolio better than trendy negative tracking.

## Verification checklist

- [ ] `npm run build` passes.
- [ ] Rendered SVGs contain padded `viewBox` and remain valid XML/SVG.
- [ ] The served deck returns 200.
- [ ] Key SVG assets return 200.
- [ ] The browser-visible default diagram view shows all borders/content without bottom/right clipping.
- [ ] If opened on a remote device, verify from that device via curl/browser and use a cache-busted URL after style changes.
