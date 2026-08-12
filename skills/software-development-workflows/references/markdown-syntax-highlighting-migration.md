# Markdown syntax-highlighting migration notes

Use when upgrading a React/Next markdown renderer from `rehype-highlight` / Highlight.js to Shiki-style highlighting, especially for notes/chat/code-heavy UIs.

## Proven migration shape

0. **Do not start with a main-editor package migration.** If the current product stores canonical Markdown and already has a CodeMirror write surface, keep that as the production adapter while improving shared renderer/components. Treat Milkdown/MDXEditor as separate spikes only after CodeMirror polish exposes a real ceiling. Shiki is a code-highlighting migration, not an editor-engine migration.
1. **Inspect all markdown entry points first.** Search for `ReactMarkdown`, `rehypeHighlight`, `rehypeRaw`, `rehypeSanitize`, `remarkGfm`, `remarkMath`, and shared `CodeBlock` usage. Common surfaces: editor preview, chat messages, quiz/explanation markdown, docs/syntax guide pages.
2. **Keep markdown parsing/sanitization separate from code highlighting.** Let `react-markdown` parse Markdown and existing `rehype-raw` + `rehype-sanitize` policy handle raw HTML. Override `pre`/`code` to render fenced code blocks through a controlled code-block component.
3. **Preserve fence metadata before sanitize.** `rehype-sanitize` can strip HAST metadata, so add a small remark plugin that copies safe code-fence `meta` into an allowed property such as `dataCodeMeta`, and explicitly allow that attribute in the sanitize schema. Then parse titles from patterns like `title="app.ts"` or `filename=app.ts`.
4. **Shiki rendering pattern for client components:** lazy import Shiki only inside the code-block component/effect so pages without code fences do not pay the cost up front. Cache highlighted HTML by `theme:language:hash(code)` and bound the cache (for example 100 entries) to avoid long-session memory growth in live preview/chat surfaces.
5. **Handle stale async highlights.** Clear current highlighted HTML on cache misses before starting async highlighting, and guard the async result with a cancellation flag so React does not show stale highlighted code after note switches or live edits.
6. **Fallbacks and aliases:** normalize common aliases (`gitignore -> ini`, `shell/sh/zsh -> bash`, `mjs/cjs -> javascript`, `env -> dotenv`) and fall back to plaintext for unsupported languages.
7. **Code-block UX:** always show a header, copy button, language label, and wrap/unwrap toggle. Copy the raw code string, not rendered token text. Keep plaintext fallback safe with React-escaped `<code>{code}</code>`.
8. **Update tests:** add SSR/static-render tests that fenced code renders as a block with copy/wrap chrome, unsafe HTML remains escaped/sanitized, math still renders if applicable, and fence titles survive sanitization.

## Performance tradeoffs to call out in PRs

- Shiki produces higher-quality TextMate-style highlighting than Highlight.js/Prism but is heavier and usually slower. The first code block may fetch/initialize a large deferred chunk.
- `shiki/bundle/web` is a good first migration because it lazy-loads in modern bundlers and covers web languages broadly, but it can still add hundreds of KB gzip in deferred chunks depending on chunk splitting.
- If code blocks are common on first-load surfaces or bundle budgets tighten, move to a fine-grained `shiki/core` setup: one or two themes, a curated language list, and the JavaScript regex engine (`shiki/engine/javascript`) for browser bundle control. Consider highlight-on-viewport or parent-level debounce for large live previews.
- Include measured local numbers in the PR body: production build success plus a rough scan of Shiki-related `.next/static/chunks` raw/gzip sizes. Label them as rough because shared chunks can be double-counted by content matching.

## Verification checklist

- `npm run test:ci -- <focused markdown renderer test>`
- `npx tsc --noEmit`
- `npm run lint`
- `npm run build`
- Direct SSR render probe for fence metadata if tests are not enough.
- `gh pr checks --watch` after opening the PR.

## Pitfalls

- Do not remove sanitization just because Shiki escapes code. Raw markdown HTML and fenced code text are different flows.
- Do not claim fence-title support unless metadata survives the sanitize pipeline.
- Do not leave an unbounded module-level highlight cache in live preview/chat UIs.
- Do not oversell renderer/highlighter changes from implementation diffs alone. For code-block polish, the user-visible question is whether screenshots make the improvement obvious. Generate zoomed crops around actual code blocks, inspect them yourself, and state plainly when a branch is only plumbing/architecture rather than visible UX improvement.
- Beware noisy controls in reading surfaces. Text buttons like repeated `Wrap` beside every code fence can make Shiki or code-block UX look heavier even if token highlighting is technically better. Prefer quiet/icon controls, hover/focus reveal, or compact menus.
- If evaluating a single-place Markdown editor/viewer, distinguish three surfaces: the write editor, the read renderer/syntax guide, and secondary renderers like chat/quiz. A fixture note shown in write mode may not prove renderer polish at all.
- If the repo's full pre-commit suite has unrelated baseline failures, document the failure class and run focused tests/typecheck/lint/build before using `--no-verify`; do not pretend the full suite passed.
