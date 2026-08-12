# Slidev + Mermaid deck polish notes

Use when turning Mermaid architecture diagrams into a Slidev deck, especially for Semyon-style technical demos.

## Style / smell checks

- Avoid default-theme orange/amber accents and left-border callout bars; they read as generated slideware.
- Prefer restrained dark grey panels, thin neutral borders, small muted helper text, and only one subdued accent colour if needed.
- Do not rely on Slidev default theme styling staying global. If styles in `slides.md` are ignored or scoped, use `<style global>` or a real root `style.css`.
- Code accents should be neutral/cool (`#dbeafe`, zinc/blue-grey), not yellow/orange highlighter colours.

## Diagram fit / clipping fixes

Mermaid SVGs can render with a viewBox exactly on the outer stroke/text bounds. When embedded in a fixed-height, `overflow: hidden` Slidev frame, bottom/right borders can look clipped.

Robust pattern:

1. Render `.mmd` to SVG/PNG with Mermaid CLI.
2. Post-process SVGs to pad the `viewBox` by a safe margin, e.g. 64–96 px on all sides.
3. Insert any marker comment **after** the opening `<svg ...>` tag, not inside the tag. `<svg <!-- comment --> ...>` makes the SVG invalid and browsers show a tiny broken-image icon.
4. In the Vue component, fetch the SVG text and read its `viewBox`; use that width/height for layout rather than relying on `naturalWidth`/`naturalHeight` from SVG images, which browsers may report as a small default/thumbnail size.
5. Fit using `scale = min((frameWidth - margin) / svgWidth, (frameHeight - margin) / svgHeight)`, then center with translated x/y offsets.
6. Add a visible `fit` button and a `100%` button; default to fit-to-frame.
7. Use a cache-busted SVG URL or no-store fetch when regenerating diagrams during iterative work, otherwise the browser may show stale SVG dimensions.

## Silent clipping pitfalls

- Avoid `overflow: hidden` on code blocks unless you intentionally want cropped snippets. Use `overflow: auto` for proof/code slides so content is not silently missing.
- Fixed frame heights are fine only if the diagram is auto-fitted inside them. Do not assume `img { width: 100% }` prevents vertical clipping.
- Visually inspect at the actual presentation viewport after build, not just source/rendered SVG files.

## Verification

- Run the build.
- Inspect at least one wide architecture diagram and one tall/evolution/ERD diagram in-browser.
- Check the rightmost and bottom-most boxes/borders are fully inside the frame.
- Check no orange/amber callout bars remain on cards/code/callouts.
