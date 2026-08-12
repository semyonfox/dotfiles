# Markdown editor theme unification

Use when a CodeMirror-backed Markdown write surface and rendered Markdown preview feel visually mismatched.

## Durable lesson

Do not let the editor import an independent syntax/theme personality while the preview uses app CSS. In OghmaNotes this happened when CodeMirror used `oneDarkHighlightStyle` / `defaultHighlightStyle` while rendered Markdown code blocks used separate hard-coded highlight.js colours. The result looked like two different products even though both surfaces were functionally correct.

## Preferred pattern

1. Define shared Markdown/editor semantic CSS variables at app theme level:
   - `--md-text`, `--md-text-muted`, `--md-text-faint`
   - `--md-link`, `--md-link-hover`, `--md-accent`
   - `--md-selection`, `--md-active-line`
   - `--md-code-bg`, `--md-code-border`, `--md-surface-subtle`
   - syntax roles: `--md-syntax-comment`, `--md-syntax-keyword`, `--md-syntax-string`, `--md-syntax-number`, `--md-syntax-function`, `--md-syntax-type`, `--md-syntax-variable`, `--md-syntax-invalid`
2. Add light-mode overrides for those variables instead of branching all editor colours in TypeScript.
3. Replace imported CodeMirror highlight styles with an app-owned `HighlightStyle.define(...)` using the same CSS variables. Keep `EditorView.theme(spec, { dark })` so CodeMirror internals still know the theme polarity.
4. Map rendered Markdown/highlight.js classes to the same variables, so preview code blocks and editor code tokens share a palette.
5. Align prose affordances too: links, inline code pills, blockquote accent, checkbox/list markers, selection and active-line colour.
6. Do not treat heading colour as a substitute for heading hierarchy. Explicitly set rendered Markdown `h1`–`h6` font sizes and matching CodeMirror `.cm-header-1`–`.cm-header-6` sizes; otherwise headings can still feel like body text with accent colours. For OghmaNotes, a desktop visual target that worked was roughly H1 `56px`, H2 `42px`, H3 `30px`, with H4/H5/H6 still above body size.
7. Prefer app palette roles over external theme colours. For OghmaNotes specifically, use slate surfaces plus indigo accents, teal types, amber numbers, green strings, red invalid/deletion.

## Accessibility checks

- Light-mode `primary-400` can be too low-contrast for prose links; prefer `primary-600`/`primary-700` in light mode.
- Imported One Dark/One Light comment greens/grays can fail contrast on app backgrounds. Use app-token values and verify comments, links, and code tokens remain readable.
- Do not over-colour prose: body, headings, strong text should mostly remain app text colour; reserve accents for interactive/structural elements.

## Implementation shape

- Keep theme/layout code in a small editor theme module rather than bloating the React editor component.
- If importing Lezer tags directly (`@lezer/highlight`), make it an explicit dependency instead of relying on transitive CodeMirror packages.
- Remove unused external theme packages after replacing them.
- Before patching, inspect the current integration branch's editor architecture. OghmaNotes may have already moved from a raw `source-editor.tsx` component to a split `write-editor.tsx` + `write-editor-theme.ts` setup; port the visual intent to the active theme module instead of forcing stale file paths.
- For PRs from a dirty normal checkout, use a clean temporary worktree based on `origin/dev` and manually port the semantic changes. A raw `git diff` from the normal checkout can fail if `dev` advanced or files were renamed while the local patch was being developed.
- With Tailwind v4-style `@theme`, do not assume arbitrary app/editor CSS variables declared inside `@theme` will be available as runtime custom properties. Put non-Tailwind semantic editor tokens such as `--md-*` in normal `:root` / `html.light` rules, then verify with `getComputedStyle(document.documentElement).getPropertyValue('--md-link')` before trusting the visuals.
- For production visual checks after global CSS/token changes, run a real build and serve it briefly on an alternate port rather than relying only on a stale dev server. If `next build` rewrites `next-env.d.ts` because the dev server normally owns it, restore the prior import before finalizing so unrelated generated noise is not left in the diff.

## Verification

Run normal local gates plus visual smoke:

```bash
env -u NODE_ENV -u NEXT_PUBLIC_APP_URL npm run lint -- <changed editor/theme files>
env -u NODE_ENV -u NEXT_PUBLIC_APP_URL npm run test:ci -- src/__tests__/components/write-editor.test.ts src/__tests__/lib/preview-renderer.test.ts
env -u NODE_ENV -u NEXT_PUBLIC_APP_URL npm run build
env -u NODE_ENV -u NEXT_PUBLIC_APP_URL npm run test:ci
```

Browser-verify both light and dark themes with a sample note containing headings, bold/italic, inline code, links, bullets, todos, blockquotes, and fenced code. Check console output and make sure no CodeMirror/default-highlight colours visually survive as a foreign island. For heading-size changes, do not rely on eyeballing alone: inspect computed `fontSize` for `.markdown-preview h1,h2,h3` in the browser console and record the actual px values in the PR body or final summary.

If committing in OghmaNotes, remember Husky may run the full `lint:all` pre-commit. Explicitly unset leaked `NODE_ENV` and `NEXT_PUBLIC_APP_URL` in the committing shell as well as in manual verification commands; otherwise unrelated tests can see local dev URLs or stricter development settings and fail despite the styling change being sound.
