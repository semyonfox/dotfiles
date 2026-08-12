# Discord SVG/infographic cleanup notes

Use when turning research/comparison data into Discord-ready SVG/PNG charts or when a user says generated visuals are ugly, unreadable, clipped, or "AI-looking".

## Failure pattern observed

A first-pass SVG chart exported through ImageMagick rendered huge, mangled title text and caused severe overlap/clipping. The source looked structurally valid, but inherited/embedded CSS and font handling made the PNG unusable. Scatter/bubble labels also collided and were hard to read on Discord/mobile.

## Better workflow

1. Treat Discord as the target surface, not a generic browser canvas.
   - Use wide, high-resolution PNG exports, e.g. 1600-1800px wide.
   - Keep all key text readable after Discord preview scaling.
   - Prefer fewer labels and larger type over dense table/detail dumps.
2. Use explicit SVG attributes for text.
   - Put `font-family`, `font-size`, `font-weight`, `fill`, and `text-anchor` directly on each `<text>` element or in very simple CSS.
   - Avoid complex CSS class inheritance if exporting with ImageMagick/convert.
   - Avoid oversized background decorative text unless visually verified after rasterization.
3. Simplify charts that do not serve the reader.
   - Replace noisy scatter/bubble plots with ladders, cards, or routing matrices when exact numeric axes are heuristic.
   - Use `low → high`, `none → max`, or similar compact labels rather than long comma-separated lists in narrow columns.
4. Visually review the actual exported PNG, not just the SVG source.
   - Check title scale, text collisions, clipping at edges, footer visibility, and Discord/mobile readability.
   - If available, run a visual reviewer such as Gemini/vision to describe what looks wrong, then edit the SVG source.
   - If the requested visual reviewer is unavailable due to auth/setup, do not stop; use local vision inspection and report the auth issue plainly.
5. Iterate once more after fixes.
   - Re-export PNGs.
   - Inspect again for overlaps and truncation.
   - Bundle both clean PNGs and SVG sources if the user asked for editable assets.

## Design defaults that worked

- Dark background: `#0b1220`
- Card panels: `#0f1b2d`, `#111827`, `#172033`
- Text: `#f8fafc`; muted text: `#cbd5e1` or `#94a3b8`
- Accent colors: orange `#f97316`, green `#22c55e`, blue `#38bdf8`
- Layouts:
  - Matrix/card table for specs.
  - Horizontal bar chart for costs.
  - Three-column ladder for routing/escalation guidance.

## Red flags before delivery

- Huge cropped letters behind foreground content.
- Labels colliding with points/bubbles.
- Table columns too narrow for reasoning lists.
- Footer text cut off.
- Any claim that a chart is "clean" without inspecting the exported PNG.
