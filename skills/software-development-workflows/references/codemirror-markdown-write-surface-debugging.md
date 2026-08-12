# CodeMirror-backed Markdown write surface debugging

Use this when polishing the OghmaNotes Markdown editor after the single-surface migration.

## Current architecture distinction

- The product no longer has an obvious separate `Source / Read` mode UI, but the active writing surface is still CodeMirror-backed.
- `src/components/editor/markdown-editor.tsx` dynamically imports `./write-editor`.
- `src/components/editor/write-editor.tsx` owns the editable surface, selection, shortcuts, hidden Markdown marker decorations, and external value sync.
- `src/components/editor/write-editor-theme.ts` owns CodeMirror theme/highlight styling.
- Render-only Markdown paths such as `preview-renderer.tsx` / `src/lib/markdown/renderer` are separate from the editable surface. Do not confuse `react-markdown`/remark/rehype/MDX-style rendering with the editor engine.

## Heading-size pitfall

When changing visible heading sizes in the editor, patch both layers deliberately:

1. Static theme selectors such as `.cm-header-1`, `.cm-header-2`, `.cm-header-3` in `write-editor-theme.ts`.
2. The `HighlightStyle.define(...)` entries for `tags.heading1`, `tags.heading2`, `tags.heading3`.

CodeMirror 6 may render generated highlight classes like `ͼp`, `ͼq`, `ͼr` instead of literal `.cm-header-1` classes on the visible spans. If only `.cm-header-*` is changed, the diff can look right while the live editor barely changes.

## Verification pattern

- Search current `origin/dev` before patching; this area moves quickly and stale local files may be behind.
- Verify the active editor path, not just global `.markdown-preview` CSS.
- For CodeMirror token styling, inspect the generated live CSS/classes in a mounted editor or built bundle. A real success for heading scale includes generated token classes with the intended `font-size`, e.g. `2.65em`, `2.05em`, `1.55em` for h1/h2/h3.
- After pushing to `dev`, Jenkins success is not enough: confirm the `oghma-dev` container image/started time and grep the deployed `.next` bundle/container for the expected compiled style values before telling Semyon it is live.

## Dependency cleanup guidance

Do not drop CodeMirror merely because the UI is now “Notion-ish” or no longer exposes source/read tabs. CodeMirror is still required while `write-editor.tsx` imports `@codemirror/*`. Safe cleanup candidates are stale docs/report wording and possibly dependency shape, not removal of CodeMirror itself unless the editable surface is replaced.
