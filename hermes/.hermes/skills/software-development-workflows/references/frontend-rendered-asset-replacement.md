# Frontend rendered-asset replacement notes

Use when replacing public landing-page screenshots with generated diagrams or other documentation artifacts.

## Pattern

1. Locate the rendered media usage in the page and metadata, not just visible JSX. Search for old asset names in:
   - page components
   - `metadata.openGraph` / `twitter.images`
   - JSON-LD structured data
   - layout-level metadata
2. For Next.js `Image`, copy any source files outside `public/` into a stable public path such as `public/diagrams/`; do not point public pages at repo-only paths under `diagrams/rendered/`.
3. Use `file`/image dimensions or another reliable probe for `width`/`height`, especially for generated Mermaid diagrams.
4. Prefer a readable, current architecture diagram as the hero image. Very large “architecture evolution” diagrams can become tiny/mostly white in the hero viewport; use them as a secondary card unless the design is specifically for zoomable documentation.
5. Keep diagram cards on a white surface if the diagrams were rendered for white backgrounds, and use `object-contain` with a max height so wide diagrams remain visible rather than stretching the page.
6. If the user says “remove screenshots of the app”, also update social/SEO images that point at screenshot assets, not only the visible page.

## Verification

- Run targeted lint on the touched page/layout files.
- Run `npm run build` for Next.js changes.
- Use browser inspection or accessibility snapshot to confirm image alt text now references diagrams, not app screenshots.
- Take a visual pass at the relevant scroll position; a DOM image can be technically loaded but visually useless if the diagram is too pale, too large, or below a huge blank gap.
