# Markdown renderer and syntax highlighting upgrade reconnaissance

Use this when comparing a project's Markdown/code rendering to a modern AI-chat/editor reference such as T3 Code, or when planning a visible Markdown UX bump.

## Recon checklist

1. Locate all Markdown render paths, not just the obvious editor preview:
   - central renderer (`src/lib/markdown/renderer.tsx`, `MarkdownRenderer`, etc.)
   - editor preview renderer
   - chat/AI message renderer
   - quiz/explanation/documentation renderers
   - source editor implementation (CodeMirror/Monaco/etc.)
2. Inspect dependencies and lockfile for the actual stack:
   - `react-markdown`, `remark-*`, `rehype-*`
   - `rehype-highlight`/`lowlight`/`highlight.js`
   - `shiki`, `@shikijs/*`, `react-shiki`, or wrapper packages
   - CodeMirror language/highlight packages for source mode
3. Check sanitize ordering and allowed attributes/classes before changing highlighting:
   - `rehype-raw` before sanitization if raw HTML is intentionally supported
   - sanitize schema must preserve whatever the highlighter emits
   - Shiki HTML often uses inline styles; Highlight.js uses `hljs-*` classes
4. Read the code-block component itself:
   - copy button availability
   - language label fallback (`CODE`/`text`)
   - line wrapping toggle
   - code-fence metadata/title support
   - raw-content extraction for clipboard
   - fallback path for unsupported languages
5. Check editor source mode separately. CodeMirror Markdown highlighting can be good even when rendered preview highlighting is weak.

## T3 Code-style pattern worth reusing

T3 Code's web renderer keeps `react-markdown` for Markdown parsing but replaces `rehype-highlight` with app-level Shiki rendering:

- `react-markdown` + `remark-gfm` (+ optional `remark-breaks`)
- `rehype-raw` + `rehype-sanitize`
- custom `pre` override extracts the code block and fence metadata
- Shiki highlighter renders fenced code via `codeToHtml`
- highlighter promises are cached by language
- rendered highlighted HTML is cached by `hash(code):length:language:theme`, but not while streaming
- unsupported languages fall back to `text`
- small alias fixes can be useful (`gitignore -> ini`)
- code block chrome includes language/file title, copy, and word-wrap controls

This is more polished than `rehype-highlight`/Highlight.js because it produces IDE/TextMate-grade highlighting and gives the app one place to own code-block UX.

## Safe migration shape for a Next/React notes app

Prefer a small PR sequence instead of a broad renderer rewrite:

1. First improve the existing `CodeBlock` chrome with no highlighter swap:
   - always show a header
   - show language or `CODE`
   - always offer copy
   - add word-wrap toggle
   - preserve raw code for clipboard
2. Add fence-title/meta preservation if the current markdown pipeline drops it.
3. Introduce a Shiki-backed code renderer behind the existing `CodeBlock` API.
4. Remove `rehype-highlight` from each render surface only after the Shiki path works there.
5. Shrink/delete `.hljs-*` CSS once no render path emits Highlight.js classes.
6. Keep math/GFM/sanitize behavior unchanged unless there is a specific bug.

## Verification

Add focused renderer tests for:

- fenced code with a known language
- unknown language fallback
- fence title/meta preservation
- copy uses raw code, not rendered/tokenized text
- sanitization still blocks unsafe HTML/attributes
- math/GFM still render if the app supports them

Then run the project's normal lint/test/build gates and visually inspect at least one code-heavy Markdown note/message in light and dark mode.

## Pitfalls

- Do not assume source editor syntax highlighting and rendered preview syntax highlighting use the same system.
- Do not drop sanitization to make Shiki HTML work; adapt the render path/schema safely.
- Do not port chat-agent-specific file-link/task-list behavior into a notes app unless it maps to a real product feature.
- If the repo has a dirty working tree, report a proposed patch plan rather than editing over unrelated user work.
