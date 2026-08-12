# Slidev zoomable SVG controls

Session lesson from the OghmaNotes architecture deck: Semyon wanted zoomable SVGs restored after a cleanup pass removed them, but not the old hidden/fragile behaviour.

## Preferred pattern

For architecture/back-pocket SVGs in Slidev:

- Keep zoom controls visible and small: `− / percentage reset / +` in the diagram toolbar.
- Use a bounded zoom range, e.g. `100%` to `300%`.
- Make the percentage button reset the view.
- Enable drag/pan only when zoomed above `100%`.
- Avoid accidental live-talk behaviour: plain wheel should not zoom; require a deliberate modifier such as `Alt`, `Ctrl`, or `Cmd` for wheel zoom.
- Keep the SVG inside an `overflow: hidden` frame with dark deck surface/background tokens.
- Do not append cache-busting `?v=...` query strings to SVG URLs unless explicitly debugging stale assets; Semyon asked to drop that.

## Verification checklist

After changing the component:

1. Run `npm run build`.
2. Check the hosted root and a representative SVG asset return `HTTP 200`.
3. Browser visually inspect at least:
   - a main-flow SVG slide at `100%`
   - the same slide zoomed once
   - an appendix/back-pocket SVG slide at `100%`
   - the same appendix slide zoomed once
4. Confirm controls are visible but unobtrusive, the diagram remains contained, and no clipping or artefacts appear.

## Anti-patterns

- Removing zoomability entirely during cleanup when the deck uses diagrams as back-pocket architecture material.
- Hidden wheel zoom or drag behaviour with no visible controls.
- Letting normal wheel scrolling zoom diagrams during a live presentation.
- Large toolbar chrome that competes with slide content.
- Reintroducing cache-busting URL suffixes into user-facing hosted URLs or asset paths.
