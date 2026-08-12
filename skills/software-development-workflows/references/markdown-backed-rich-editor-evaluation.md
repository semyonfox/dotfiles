# Oghma-style Markdown editor evaluation notes

Use when evaluating a Markdown-backed note editor that aims to feel like one clean editor/viewer rather than a source/preview split.

## Product target

The right target is a **canonical Markdown-backed rich writing surface**:

- normal users write in one document-like surface;
- advanced users can type Markdown shortcuts naturally;
- saved data stays portable Markdown;
- inactive content looks rendered/readable;
- active content reveals raw Markdown only where editing needs it.

For Oghma-like student/technical notes, this is closer to **Notion feel + Obsidian data model** than to MDX or a split preview app.

## What to inspect first

1. Current editor engine and source of truth.
2. Current renderer stack and every surface that renders Markdown: notes, chat, quiz, syntax guide, export.
3. Whether math exists in both renderer and writer.
4. Whether Markdown behavior is centralized or duplicated.
5. Whether screenshots show the write editor or the read renderer; do not mix conclusions between them.

## Feature tiers

### Tier 1 — must be excellent

- headings;
- bold / italic / strikethrough;
- ordered/unordered lists;
- task lists with eventual clickable checkbox toggles;
- links;
- inline code.

### Tier 2 — must work, polish over time

- fenced code blocks with language/title/copy/wrap/unknown fallback;
- blockquotes/callouts;
- tables;
- images/assets;
- inline and display math.

### Tier 3 — optional/lazy

- Mermaid;
- raw HTML, tightly sanitized and not promoted as primary syntax;
- MDX/component authoring only if the product explicitly becomes component docs, not normal notes.

## Math guidance

Math should be first-class for student/technical notes:

- keep `remark-math` + `rehype-katex` in the shared renderer;
- add writer widgets/decorations so inactive `$...$` and `$$...$$` render as KaTeX;
- keep active math raw/editable;
- cache/debounce math rendering and render only visible ranges;
- show invalid LaTeX subtly rather than breaking the document.

## Engine choice heuristic

Start by pushing CodeMirror further if Markdown is canonical. It is strong for cursor behavior, plain-text fidelity, keyboard handling, diff/sync/export, and AI/search ingestion.

Consider Milkdown/ProseMirror only if CodeMirror cannot satisfy rich block interaction needs such as table editing, drag-reordered blocks, or true WYSIWYG widgets. Avoid treating MDXEditor as the default unless plain Markdown round-tripping is proven.

## Architecture shape

- Keep Markdown as the canonical note body.
- Use one write surface component.
- Use block-aware decorations/widgets for active-vs-inactive rendering.
- Centralize Markdown rendering with explicit variants, e.g. `note`, `chat`, `quiz`.
- Use one shared `CodeBlock` component for all surfaces.
- Lazy-load heavy features: Shiki, Mermaid, complex math/render widgets.

## Evaluation pitfalls

- Do not recommend Shiki just because it is technically higher quality. If the code-block chrome is noisy or perf drops, it is not yet a product win.
- Do not call architecture cleanup a visible UX improvement.
- Do not use a write-mode note screenshot to prove read-renderer polish.
- If the user cannot notice a difference, make better zoomed screenshots and reassess; the branch may simply not improve the product visibly.
