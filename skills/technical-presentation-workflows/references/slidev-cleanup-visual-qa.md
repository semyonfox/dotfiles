# Slidev cleanup visual QA notes

Reusable detail from an OghmaNotes Slidev cleanup pass.

## Card accent dots

If small orange dots/markers are visually out of line with card headings, avoid absolutely positioned `.route::before` markers. They drift because the dot is tied to card padding rather than the heading text metrics.

Prefer making the marker part of the heading layout:

```css
.route h3 {
  display: flex;
  align-items: baseline;
  gap: 0.46rem;
  margin: 0 0 0.45rem;
}

.route h3::before {
  content: "";
  flex: 0 0 auto;
  width: 0.34rem;
  height: 0.34rem;
  border-radius: 999px;
  background: var(--oghma-accent);
  opacity: 0.78;
  transform: translateY(-0.08em);
}
```

Then verify in browser with screenshots, not just by reading CSS.

## Slidev server/port warning

A background `npx slidev ... --port 3037` process reporting `Port 3037 is already in use` is not automatically a deck failure. Check whether an existing static/dev server is already serving the deck with `curl -I` or browser navigation before restarting/killing anything.

## Cleanup pass sequence

For visual cleanup requests, make a small CSS/component change, rebuild, then browser-check the affected slide(s). For final confidence, inspect every slide if the user explicitly asks for browser QA before finishing.
