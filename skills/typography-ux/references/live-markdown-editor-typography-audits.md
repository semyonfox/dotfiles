# Live Markdown editor typography audits

Use this when auditing a deployed Markdown editor or all-in-one writing surface, especially OghmaNotes-style CodeMirror editors where Markdown remains canonical but inactive syntax is rendered or hidden.

## Key lesson

Do not stop at static CSS or an unauthenticated public docs page when the real editor is behind auth. The actual editor may have newer deployed CSS, different CodeMirror decorations, and different runtime semantics than the local branch or public renderer.

If the user explicitly authorizes access, create or use a bounded test auth path, inspect the live editor DOM, and clean up any temporary account/data afterward.

## Workflow

1. **Clarify target surface by URL/branch/deployment.**
   - `dev.oghmanotes.ie` means the live dev deployment, not necessarily the local `dev` branch.
   - Check whether local findings are stale before reporting them as live truth.

2. **Reach the actual editor.**
   - If unauthenticated routes redirect to `/login`, do not declare the editor unauditable if the user has authorized test access.
   - Prefer a throwaway test account/session with no real user data.
   - Before inserting or changing any test auth row, verify the exact deployment database name/URL/container (`dev` vs `prod`) and keep the query scoped to one clearly fake email/user.
   - Avoid real account changes, production data mutation, or broad DB edits.
   - After the audit, remove temporary accounts/notes if you created them and verify cleanup with a count query returning `0` in every environment you touched.

3. **Use a representative Markdown fixture.**

   ```md
   # Main Heading

   Plain paragraph body text with **bold**, *italic*, `inline code`, and [a link](https://example.com). This line is long enough to inspect measure and wrapping.

   ## Section Heading

   - First list item
   - Second list item

   > A quote with enough text to inspect quote border, background, and line height.

   ```js
   // comment should be readable
   const value = 42;
   ```
   ```

4. **Inspect computed styles, not just source tokens.**
   - `.oghma-write-editor .cm-content`
   - `.cm-line`
   - heading spans/decorations
   - inline code/link/emphasis spans
   - quote lines
   - fenced-code lines and comment spans
   - toolbar/status labels
   - relevant CSS variables: `--md-syntax-comment`, `--md-code-bg`, `--md-heading-marker`, `--md-quote-border`, `--md-text`, `--md-text-muted`, app background/text tokens.

5. **Calculate contrast against the actual composite background.**
   - Body and small toolbar/status text need 4.5:1.
   - Large heading text can use 3:1 but should normally exceed it.
   - Semantic boundaries like quote bars/table borders should aim for 3:1 if they carry structure.
   - Code comment colors must be checked against the code-block background, not only page background.

## What to look for

- Editor body at least `16px`; `line-height` around `1.5–1.75` depending on writing comfort.
- Editor prose uses app sans; monospace is reserved for inline/fenced code.
- Rendered/hidden Markdown syntax behaves consistently: headings, lists, links, emphasis, quotes, and code blocks should not mix raw and rendered affordances randomly.
- Quote blocks should look semantic. If `>` is hidden but no quote border/background appears, meaning has been lost.
- Fenced code blocks should have block chrome/background, not just syntax-colored floating lines.
- Heading markers should not visually compete with heading text. Prefer hidden-on-inactive or low-emphasis markers that become visible on cursor/selection.

## Reporting pattern

Report separately:

- **Live verified facts** from computed DOM/CSS.
- **Static/local code findings** if inspected separately.
- **Auth/data limitations** if the actual editor could not be reached.
- **Cleanup performed** for any temporary account/session/note.

Avoid saying “the editor fails” based only on public docs or stale local branch findings when the live authenticated editor differs.
