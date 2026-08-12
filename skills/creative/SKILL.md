---
name: creative
description: "Use when generating or transforming creative artifacts such as diagrams, infographics, sketches, motion pieces, generative art, slides, or stylized text and audio."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]

metadata:
  harness: [hermes]
---

# Creative Artifact Workflow

## Overview

Use this skill when the user wants something expressive, visual, audio, or presentation-like rather than a plain document or code artifact. This umbrella covers diagrams, infographics, mockups, ASCII art/video, generative art, slides, and stylized audio or text transformations.

The common pattern is: pick the medium, choose the rendering/style system, generate or edit with clear constraints, and verify the result in the target format.

## When to Use

- The user asks for a diagram, infographic, sketch, or design mockup
- The user wants ASCII art/video, generative art, or p5.js-style output
- The user wants slide or presentation-style visual composition
- The user wants audio or music generation, audio analysis, or stylized media output
- The user wants text humanization or a more natural creative rewrite

## Core Creative Families

### Diagrams and visual explanation
Use these when the goal is structure, architecture, or process clarity:

- architecture diagrams
- Excalidraw-style hand-drawn flows
- infographic layouts
- design-system inspired web mockups

### Slides and presentation assets
Use these when the output should be presentation-ready:

- PowerPoint-style decks
- polished design mockups
- structured content-to-slide workflows

### Generative visuals and code art
Use these when the work is expressive, animated, or interactive:

- ASCII art and ASCII video
- p5.js sketches
- Manim-style explanatory animations
- sketch/prototype-style HTML mockups
- pretext / browser-demo style creative artifacts

### Audio and music
Use these when the user wants sound, music, or audio-centric creative work:

- AI music generation workflows
- audio generation and transformation workflows
- audio feature / spectrogram analysis when the task is creative rather than purely technical

### Text style, humanization, and personal technical prose
Use these when the user wants prose to sound more natural, less robotic, or more polished:

- humanizer-style rewriting
- personal technical blog posts and portfolio writing, especially when turning real configs/repos into public-facing prose

For Semyon's personal technical blog workflow, see `references/personal-technical-blog-posts.md`: inspect the repo/content schema, match existing voice, write the actual content file, verify the build, and avoid leaking private infrastructure details.

## Practical Workflow

1. Identify the artifact type and medium.
2. Choose the narrowest rendering tool or workflow that matches the medium.
3. Define style constraints early: color palette, tone, layout, motion, size, audience.
4. When the request targets an existing site or portfolio page, inspect the actual repository, asset wiring, and locally rendered page *before* suggesting an image direction or generating anything. A request such as “check my portfolio” is an instruction to ground the work in that surface immediately, not an invitation to give general asset advice.
5. For a replacement batch of generated site imagery, check image-generation provider readiness before launching a multi-image job. Then generate into the stable public asset path, preserve the existing dimensions/aspect ratio where possible, wire or retain the content references, and visually inspect the real page at its card/hero size. Do not claim the assets were updated if generation has not produced files.
6. Generate a first pass quickly, then iterate on the strongest candidate rather than overfitting the first idea.
7. For Mermaid diagrams that must be embedded as images, render to a real web-safe image asset rather than handing off Mermaid/SVG text as if it were an image. A reliable pattern is: write `.mmd` source, render with Mermaid CLI to transparent PNG (`-b transparent`), convert/compress to WebP, and keep the source file for regeneration. For Slidev decks with zoomable SVG diagrams, also see `references/slidev-mermaid-deck-workflow.md` for SVG viewBox padding, autofit, and deployment verification patterns.
8. For Discord-ready SVG/PNG infographics, design for the actual preview surface: large readable type, explicit SVG text attributes, compact labels, no decorative text that can rasterize huge, and visual QA of the exported PNG before delivery. If a first-pass chart looks bad, use Gemini/vision-style critique to identify concrete layout problems, then regenerate rather than defending it. See `references/discord-svg-infographic-cleanup.md`.
9. Verify the artifact in the format the user will actually consume.

### Slidev + Mermaid Architecture Decks

When building a temporary technical deck from Mermaid/SVG assets:

1. Keep the deck visually human and opinionated. For Semyon's Oghma/OghmaNotes-style decks, restrained dark cards with warm orange/amber accents are acceptable and often preferred; do not reflexively strip them just because they look like template accents. If the user complains about “AI-smelly” styling, tune the specific offender and then re-check with them rather than flattening all personality.
2. Avoid silent clipping. Slidev/HTML frames with `overflow: hidden` can hide the bottom or right border of large rendered SVG diagrams. Prefer a zoomable component that reads the SVG `viewBox`, calculates a fit-to-frame scale, and centers the image on load/resize. Keep a manual `fit` control for recovery during a live demo.
3. Pad rendered Mermaid SVG `viewBox` values before publishing. Mermaid can calculate bounds exactly on the stroke/text edge, so scaling inside a clipped frame can shave off bottom/right borders. A small post-render script that expands `viewBox` by ~64–96px on all sides is safer than relying on CSS alone.
4. Do not use invalid inline comments inside the opening `<svg ...>` tag when marking processed SVGs; insert comments after the opening tag instead.
5. For code slides, avoid `overflow: hidden` unless the omission is deliberate. Use `overflow: auto` or split the snippet; clipped code looks like missing content.
6. Verify the actual served deck, not just the source: build, serve, load the page, fetch the hashed CSS asset, confirm expected accent/clipping CSS is present, and visually inspect at least the densest architecture slide.

Detailed recipe: `references/slidev-mermaid-architecture-decks.md`.

### Mermaid-to-Web Image Pattern

When a user asks for “Mermaid rendering” or an embeddable architecture image:

1. Write the `.mmd` source in the project near the consuming content, if that fits the repo structure.
2. Render with Mermaid CLI to PNG using transparent background and sufficient scale/resolution. If Puppeteer/Chromium needs setup, fix the render path (for example install a headless browser and use a Puppeteer config with `--no-sandbox` where appropriate) rather than claiming Mermaid cannot render.
3. Convert/compress the PNG to WebP for web delivery; keep PNG only if needed as a fallback.
4. Verify with real outputs: `file`, dimensions, byte size, MIME served by the dev server, and alpha-channel/corner transparency checks.
5. Visually inspect the embedded result at the actual page width. Wide flowcharts can look fine as source but become illegible in blog columns; simplify or use a vertical layout when needed.
6. For Slidev/fixed-frame SVG embeds, add a fit-to-frame layer that reads the SVG `viewBox`; do not trust browser `naturalWidth`/`naturalHeight` for SVGs. If borders look shaved off, pad the SVG `viewBox` after rendering.
7. Use a cache-busting/new filename if the dev server or browser appears to show an old image.

## Headless Blender source-model and render handoff

When a game/prototype needs original Blender assets but the host has no GUI, use portable Blender headlessly to generate the actual `.blend`, FBX exports, and a lit PNG proof render. Do not equate a Blender Python script with produced models: execute it, inspect the source/export files, render, and visually QA the PNG before sending. For Unity coordinate conversion, studio-preview composition, and archive/checksum handoff, see `references/headless-blender-unity-prop-preview.md`.

## Tool Choice Hints

- Use diagram tools for structure and architecture.
- Use infographic or slide workflows for executive-friendly presentation.
- Use ASCII or code-art workflows for playful or terminal-friendly output.
- Use generative image/video tools for polished visual composition.
- For SVG cleanup and imagery generation/editing on Semyon's device, let GPT-5.5/5.6 lead when they are good enough; escalate to Fable on Claude only when it is materially better for taste/cleanup/generation quality or the user asks for it. Use Gemini/Antigravity as the visual QA/description worker that reports what the image actually looks like back to the lead agent.
- For actual GPT-5.6 image creation through Hermes, prefer the bundled `image_gen/openai-codex` backend rather than assuming the default FAL route. Enable it with `hermes plugins enable openai-codex`; it becomes available in a **fresh** Hermes session and uses the existing ChatGPT/Codex OAuth path with the Responses image-generation tool. For a multi-asset portfolio job, ask a fresh `hermes chat --provider openai-codex -m gpt-5.6-terra` worker to generate directly into the stable public asset directory, then independently verify file type/dimensions, render the real page, visually QA for generated text/watermarks/incorrect subject matter, and run the production build.
- Use music/audio workflows when the target medium is sound rather than text.
- Use humanizer-style rewrites when the artifact is textual but the voice needs to sound more natural.

## Pitfalls

- Picking a medium that is too heavy for the user's real goal
- Mixing style exploration with final production without a checkpoint
- Forgetting to verify export quality or aspect ratio
- Overcomplicating a quick mockup with full production polish
- Treating generative output as final without checking what it actually looks or sounds like
- Over-sanitizing presentation styling into generic AI-looking grey/blue minimalism; if the user prefers a warm/orange accent, preserve it while fixing actual legibility and clipping issues
- Assuming an SVG is visible because the source rendered; inspect the embedded browser frame for bottom/right clipping, especially when the frame uses pan/zoom with `overflow: hidden`
- Over-sanitizing a visual style after feedback. If the user dislikes one “AI-smelly” cue, remove that specific cue and preserve any parts they liked; do not flatten the whole deck into generic corporate grey. Semyon may prefer warm orange/amber accents when they add character.
- Assuming a rendered SVG image will naturally fit a slide frame. Slidev/HTML `<img>` rendering of SVGs can use misleading intrinsic dimensions; inspect the actual frame/image bounding boxes or screenshot, not just the SVG source.
- Delivering chart/infographic PNGs from SVG without visually inspecting the rasterized export. SVG text/CSS can rasterize badly through tools like ImageMagick, causing huge cropped titles, overlaps, or clipped footers even when the source seems valid. Use explicit text attributes, simplify dense charts, and QA the final PNG before sending.

## Slidev + Mermaid diagram handling

When building technical Slidev decks with Mermaid assets:

1. Render Mermaid to real SVG/PNG assets and keep the `.mmd` sources.
2. For zoomable diagrams, use a component that fetches/parses the SVG `viewBox`, sets explicit rendered width/height, computes a fit-to-frame scale, and centers the image by default. Include a manual `fit`/`100%` escape hatch.
3. Mermaid can calculate `viewBox` tightly enough that outer borders look clipped after scaling in an `overflow: hidden` frame. Add safe viewBox padding after render, e.g. subtract padding from x/y and add `2*padding` to width/height. Insert any marker comment *after* the opening `<svg ...>` tag, not inside the tag.
4. Avoid silent clipping: code blocks and diagram frames should use `overflow: auto` or deliberate zoom/pan controls, not `overflow: hidden` unless the content is verified visually.
5. Verify in the actual consumption path: run the Slidev build, serve the built `dist`, navigate through the key slides, and use screenshot/DOM inspection to confirm no bottom/right borders or content are truncated.

## Slidev / Mermaid Architecture Decks

When building or revising technical Slidev decks with Mermaid diagrams, use the detailed workflow in `references/slidev-mermaid-architecture-decks.md`.

Key points:

- Render Mermaid to real SVG/PNG assets and keep `.mmd` sources.
- For SVGs in zoomable frames, parse the SVG `viewBox`, set explicit dimensions, and default to fit-to-frame; browser SVG intrinsic dimensions can lie.
- Pad rendered SVG `viewBox` margins so bottom/right borders and text are not clipped.
- Keep code blocks scrollable rather than hidden.
- For Semyon's portfolio-like technical decks, prefer dark bento cards, subtle borders, Inter heavy headings, and small fox-orange markers (`#e8702a`) over chunky orange sidebars.

## SVG / Infographic Cleanup for Discord Handoff

When generating SVG charts, model-comparison graphics, or Discord-bound infographics for Semyon:

1. Do **not** treat a syntactically valid SVG as done. Export it to the exact handoff format, usually PNG, and visually inspect the rendered output before sending.
2. Use visual QA actively. If Gemini/visual-review tooling is available and authenticated, ask it to critique readability, spacing, clipping, typography, contrast, label collisions, and mobile/Discord usability. If that tool is unavailable, still run a local vision/visual inspection pass and iterate.
3. Avoid dense scatter/bubble charts for routing advice unless labels are sparse and collision-free. For model selection, cost/performance, or escalation decisions, a **routing ladder**, compact table, or bar chart is usually clearer on Discord.
4. Make SVG text robust for raster export: explicit font sizes, sufficient canvas margins, short labels, wrapped multi-line text instead of long single-line cells, and no tiny footnotes that depend on desktop zoom.
5. Be suspicious of ImageMagick/SVG font rendering. If titles or text render at absurd sizes, regenerate with simpler SVG text, larger canvas dimensions, explicit sizing, or a different renderer if available.
6. Prefer 1600–1800px wide PNG exports for Discord readability. Keep the SVG source alongside the PNG so it can be edited cleanly.
7. If the user says a visual is bad, treat it as a workflow correction: review the actual pixels, simplify the information design, regenerate, re-export, and QA again before handing off.

## SVG Infographic Export and Visual QA

For hand-authored SVG charts or infographics intended for Discord/mobile delivery:

1. Render the actual PNG before handoff and inspect the pixels, not just the SVG source. Conversion engines can interpret CSS differently from browsers.
2. When ImageMagick is the available SVG renderer, prefer explicit `font-family`, `font-size`, and `font-weight` attributes on each `<text>` element. CSS `font:` shorthand can produce wildly oversized or malformed text in PNG exports.
3. Design for the consumption surface: generous margins, short labels, restrained column count, and 1600–1800px-wide exports are safer for Discord previews. Wrap long cells deliberately rather than relying on renderer text flow.
4. Use a vision model as visual QA eyes after every meaningful revision. Ask specifically about title scaling, overlap, clipping, footer visibility, contrast, and mobile readability. If the user's workflow distinguishes visual QA from design decisions, let the vision model describe defects and use the stronger design/coding model to revise the SVG.
5. Replace a chart type when cleanup cannot fix the communication problem. For model-routing guidance, a three-stage ladder can be clearer on mobile than a dense bubble/scatter plot.
6. Perform a final second render and visual inspection after fixes. Verify dimensions and file type, then deliver both PNGs for easy viewing and SVG sources for editing.

## Cost, usage, and forecast charts

For user-facing usage/cost charts, ground every plotted value in a machine-readable export and state the model clearly in the chart itself. Separate a conservative run-rate baseline from an intentionally aggressive expansion/stress case; do not present a short-term accelerating trend as a credible prediction without that caveat. If an exponential scenario makes historical values unreadable, use a labelled **logarithmic y-axis** and retain actual-month bars alongside forecast lines.

Suggested guardrails should be explicitly named as soft alert/review and hard approval/pause thresholds, and visually distinct from forecasts. Include the as-of date for any MTD month and its implied full-month run rate. For Discord handoff, produce a readable PNG plus editable SVG source, then inspect the final raster; move threshold labels if they collide with nearby bar or forecast labels.

When a common plotting library is unavailable, prefer a deterministic stdlib-generated SVG rendered to PNG with an available local renderer (for example ImageMagick `convert`) rather than abandoning the visual. Keep font attributes explicit and use a final visual QA pass after each label/layout correction.

## Verification Checklist

- [ ] Medium chosen correctly
- [ ] Style constraints set
- [ ] Output rendered in the intended format
- [ ] Visual/audio quality checked directly
- [ ] SVG-to-PNG export was inspected for renderer-specific typography/clipping problems
- [ ] Final artifact matches the user’s audience and use case
- [ ] Final artifact matches the user’s audience and use case
