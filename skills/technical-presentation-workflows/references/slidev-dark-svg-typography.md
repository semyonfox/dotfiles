# Slidev dark SVG + restrained typography pass

Use this reference when refining Semyon's dark technical Slidev decks with external SVG diagrams.

## User signals captured

- If orange accents disappear entirely, restore **small** orange accents rather than making the deck loud.
- Keep the grey hierarchy: dark background, slightly lifted surfaces, subtle borders, muted body copy, bright headings.
- Use **Inter** for repeatable, practical technical decks unless the task explicitly asks for a different identity system.
- Do not let appendix titles become huge just because normal slide titles are large; appendix/back-pocket slides need smaller heading scale so diagrams have room.
- WebExpo typography direction: locked type system, deliberate spacing/grouping, enough contrast, minimal colour used structurally, no generic AI-polish.

## Practical CSS pattern

Root tokens that worked well for the Oghma deck:

```css
:root {
  --oghma-bg: #0e1014;
  --oghma-surface: #171a20;
  --oghma-surface-soft: #12151b;
  --oghma-border: rgba(212, 212, 216, 0.14);
  --oghma-border-soft: rgba(212, 212, 216, 0.08);
  --oghma-heading: #f5f5f4;
  --oghma-body: #d4d4d8;
  --oghma-muted: #a1a1aa;
  --oghma-dim: #71717a;
  --oghma-accent: #ff7849;
  --oghma-accent-soft: rgba(255, 120, 73, 0.15);
  --oghma-accent-border: rgba(255, 120, 73, 0.34);
}
```

Small accent options:

```css
.kicker::before,
.route::before {
  content: "";
  display: inline-block;
  width: 0.42rem;
  height: 0.42rem;
  border-radius: 999px;
  background: var(--oghma-accent);
  opacity: 0.8;
}

.badge {
  border: 1px solid var(--oghma-accent-border);
  background: rgba(255, 120, 73, 0.055);
  color: #d6d3d1;
}
```

Appendix scale pattern:

```css
.kicker + h1 {
  font-size: 1.76rem;
  line-height: 1.12;
  margin-top: 0.15rem;
  margin-bottom: 0.72rem;
}
```

## Zoomable SVG dark-background issue

If `ZoomableSvg.vue` renders diagrams on a white/grey slab, check for hard-coded light CSS:

```css
.zoom-frame {
  background: #f8fafc;
}
```

Prefer deck tokens:

```css
.zoom-frame {
  background: var(--oghma-surface-soft, #12151b);
  border: 1px solid var(--oghma-border-soft, rgba(212, 212, 216, 0.08));
}
```

## External SVG caveat

When SVGs are loaded through `<img>`, Slidev/page CSS cannot style inside them. Fix internals by one of:

1. Regenerate Mermaid/SVG assets with dark theme variables and transparent background.
2. Post-process SVG files to inject dark override CSS inside the SVG.
3. Use an image filter only as a quick emergency fallback; it can distort orange accents and labels.

Internal SVG override pattern:

```css
svg { background-color: transparent !important; }
.node rect, .node circle, .node ellipse, .node polygon, .node path,
.entityBox, g rect.rect {
  fill: #171a20 !important;
  stroke: #52525b !important;
}
.cluster rect {
  fill: #12151b !important;
  stroke: #3f3f46 !important;
}
.label, .label text, span, foreignObject, text {
  fill: #f5f5f4 !important;
  color: #f5f5f4 !important;
  font-family: Inter, ui-sans-serif, system-ui, sans-serif !important;
}
.edgePath .path, .flowchart-link, line {
  stroke: #a1a1aa !important;
}
.edgeLabel, .edgeLabel rect, .labelBkg {
  background-color: #12151b !important;
  fill: #12151b !important;
}
```

## Verification checklist

- Build passes.
- Hosted root URL works without cache-busting query params unless the user explicitly wants one.
- Browser visual QA includes: title slide, a card-heavy slide, a code slide, at least one appendix SVG slide, and the densest full-system diagram.
- Check for over-small diagrams after fitting; increasing the frame height may be better than returning to a white background.
