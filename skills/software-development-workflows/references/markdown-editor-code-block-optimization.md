# Markdown editor + code block optimization

Use this when a React/Next notes app already has both a Markdown source editor and a rendered preview, and the user wants better syntax highlighting or a "fake markdown editor" feel.

## Key decision

Do **not** turn the typing surface into a fake rendered editor by wrapping a textarea/CodeMirror view with the rendered `CodeBlock`/Shiki component. Keep editing and presentation separate:

- **Read/preview surfaces:** use ReactMarkdown + sanitized renderers + Shiki-backed read-only `CodeBlock`.
- **Write/source surface:** use CodeMirror as the real editable surface and improve it with decorations/theme polish.

This preserves cursor behavior, selection, IME/mobile input, undo/redo, accessibility, and large-document performance.

## Recommended architecture

1. Extract shared fence helpers from the read renderer:
   - `normalizeLanguage(language)`
   - `languageLabel(language)`
   - `extractFenceTitle(meta)` / `parseFenceMeta(meta)` for `title=` and `filename=`
2. Split the rendered code block UI into a visual shell and a highlighter:
   - `CodeBlockFrame` / shell: title, language label, copy/wrap actions, rounded border/chrome
   - read-only highlighter: Shiki HTML inside the frame
3. Keep Shiki out of the live typing path. It is acceptable for preview/read surfaces, but too heavy and asynchronous for every edit.
4. In CodeMirror source mode, create a `markdownCodeBlockDecorations()` extension:
   - inspect `syntaxTree(view.state)` / markdown nodes for fenced code blocks
   - use `ViewPlugin` or a state field with `Decoration.line`, `Decoration.mark`, and optional `WidgetType` headers
   - add a small header above fenced regions showing title/filename and language
   - dim fence markers and metadata
   - style fenced lines with a dark rounded/background treatment inspired by the read-mode `CodeBlockFrame`
5. Preserve raw Markdown as the source of truth. Decorations must not modify document text.

## Why this is optimal

A fake editor built from rendered Markdown looks good in screenshots but creates hard problems: cursor drift, broken selection, scroll sync, IME/mobile bugs, accessibility regressions, expensive parsing/highlighting per keystroke, and fragile serialization. CodeMirror already provides virtualized editing, markdown parsing, code fence language support, and safe decorations; use that.

## Performance guidance

- For read mode, Shiki is higher-quality but heavier than Highlight.js. Lazy load it and cache highlighted output.
- Reserve the final code-block shell layout before Shiki finishes to avoid CLS from swapping a plain fallback `<pre>` into a taller framed block.
- If Shiki chunks become hot-path, replace `shiki/bundle/web` with a fine-grained `shiki/core` setup: one theme, common languages only, and consider the JavaScript regex engine instead of Oniguruma WASM.
- For source mode, rely on CodeMirror's `markdown({ codeLanguages })` and decorations; do not invoke Shiki on keystrokes.

## Suggested PR sequence

1. **Stabilize rendered code blocks**
   - Extract shared fence/meta helpers.
   - Render the final code block frame immediately.
   - Swap only inner highlighted content when Shiki resolves.
   - Verify with Lighthouse/Playwright that CLS and read-mode delay are acceptable.
2. **Pretty Markdown source editor**
   - Add CodeMirror fenced-code decorations.
   - Style headers, inline code, links, emphasis, and markdown punctuation.
   - Keep raw Markdown editable and round-trippable.
3. **Focus/live-preview polish**
   - Optionally hide or soften syntax markers when the cursor is outside a block/line.
   - Add task-list and link quality-of-life decorations only if they do not affect editing correctness.
4. **Bundle trimming**
   - Move from `shiki/bundle/web` to fine-grained `shiki/core` only after measurement shows the Shiki chunk matters.

## Verification checklist

- Source editor still accepts normal typing, selection, undo/redo, paste, and IME paths.
- Raw Markdown saved to the database is unchanged by decorations.
- Read mode renders unsafe HTML only through the existing sanitize policy.
- Code fence metadata survives sanitize and is displayed consistently in read/source surfaces.
- Lighthouse/Playwright compare base vs PR on an authenticated seeded note with multiple fences.
- Screenshots show both source and read modes so the user can judge whether the visual tradeoff is worth it.
