# Markdown editor typography audits

Use this reference when reviewing a Markdown editor, live preview, rendered-preview split, CodeMirror/ProseMirror writing surface, or “all-in-one” Notion-like editor.

## Trigger

- User asks about Markdown editor typography, semantic Markdown rendering, writing surface feel, heading/list/blockquote/code styling, or contrast.
- User says the editor is “all-in-one”, “Notion-like”, “semantic”, or should hide inactive Markdown syntax.
- User suspects font colours may fail contrast.

## Audit sequence

1. **Confirm the product model first**
   - Is it actually one writing surface, or still a Source/Read toggle?
   - If the user expects one surface, a permanent Source/Read split is a UX/typography smell even if both modes are styled well.
   - Preserve canonical Markdown underneath; the UI can hide/de-emphasize syntax only when inactive.

2. **Find every Markdown surface**
   - Source editor component/theme.
   - Rendered preview component.
   - Shared Markdown renderer.
   - Code block component/syntax highlighter.
   - Global Markdown CSS variables/tokens.
   - Any docs/syntax-guide/chat/AI render surfaces using the same renderer.

3. **Compare source vs rendered typography**
   - Body font size: target `16px` / `1rem` minimum for substantial writing.
   - Body line-height: usually around `1.5–1.6`.
   - Heading scale should match between edit and rendered states.
   - If headings use `em` in source mode, source base size must match preview base size or heading math drifts.
   - Prose should generally use app/body sans; reserve monospace for inline code, fenced code, URLs, or deliberately raw source mode.

4. **Check semantic block rhythm**
   - Headings need block-level rhythm, not just larger coloured token spans.
   - Lists/task items need marker visibility and readable indentation.
   - Blockquotes should style the whole semantic line/block, not only the `>` token span.
   - Inline code should be readable but not visually louder than body prose.
   - Fenced code comments are normal-sized text; comments still need contrast.

5. **Run contrast checks from actual tokens**
   - Use the app’s real light/dark backgrounds, not white/black guesses.
   - Normal text and small labels need `4.5:1`.
   - Large/bold text can use `3:1`.
   - Meaningful UI boundaries/controls should target `3:1` against adjacent backgrounds.
   - Small status labels often fail when using bright Tailwind colours on light backgrounds; prefer semantic light/dark status tokens.

## Common failure patterns

- Source editor body is `15px` while preview is `16px`; headings then become smaller in source because they are `em`-based.
- Source editor uses monospace for all prose, making an intended writing surface feel like a raw code editor.
- Rendered Markdown is tokenized and coherent, but CodeMirror source styling is token-only and lacks block-level rhythm.
- Dark syntax comments use slate/gray values that look subtle but fail `4.5:1`.
- Light-mode warning/success/error labels use `yellow-500`, `green-500`, or `red-400` and fail contrast badly at `text-xs`.
- Active segmented-control/toggle text uses generic app text on a saturated brand background and lands around `4:1`, failing for small labels.
- Markdown punctuation/heading markers are low-alpha. That is fine only if truly inactive/decorative; editable visible syntax needs accessible contrast or a focused/active state.

## OghmaNotes-specific conventions

For OghmaNotes editor work, prefer a single Notion-like Markdown surface: canonical Markdown remains the stored source, but inactive text auto-renders/hides syntax and edit/preview share one coherent palette. Avoid treating “source” and “preview” as two unrelated skins.

When auditing OghmaNotes specifically, inspect at least:

- `src/components/editor/markdown-editor.tsx`
- `src/components/editor/source-editor.tsx`
- `src/components/editor/preview-renderer.tsx`
- `src/lib/markdown/renderer.tsx`
- `src/lib/markdown/components/code-block.tsx`
- `src/app/globals.css`

## Live-site audit workflow

When auditing a live deployed Markdown editor without credentials:

1. Try obvious authenticated routes (`/notes`, `/dashboard`, known editor paths) with browser and/or HTTP status checks. If they redirect to login, clearly state the editor DOM is auth-blocked and what session/role/note access is needed; do not create accounts or mutate data unless explicitly authorized.
2. Audit any public rendered Markdown surface (for OghmaNotes, `/syntax-guide`) as a proxy for the shared renderer, but label it as renderer coverage rather than editor coverage.
3. Inspect deployed CSS/JS chunks for editor selectors that may not be reachable in DOM, especially `.oghma-write-editor`, `.cm-editor`, `.cm-content`, `.markdown-preview`, and `.md-rendered`. Distinguish “found in deployed CSS” from “confirmed active in rendered editor DOM”.
4. Compare live deployed tokens/selectors against prior local-branch findings when asked. Report improvements separately from unresolved items that still require authenticated browser verification.
5. For alpha colours (`#rrggbbaa`, `rgba()`, `color-mix()`), compute contrast against the composited background, not the raw transparent colour. Boundaries like blockquote bars and table grid lines should target ~`3:1` against adjacent backgrounds.

## Report shape

Return concise, actionable findings:

1. surfaces/routes inspected and whether auth blocked the real editor;
2. whether implementation appears to match the intended editor model, separating confirmed DOM from deployed-CSS evidence;
3. contrast failures with colour pairs and ratios where possible;
4. typography/semantic mismatches;
5. patch checklist sorted by priority;
6. what needs authenticated browser visual verification.

Do not edit by default when the worktree is dirty or the user asked for an audit/delegation. If proposing changes, give exact tokens/selectors/classes and values.