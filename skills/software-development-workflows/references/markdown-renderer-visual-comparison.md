# Markdown renderer visual comparison notes

Use when comparing Markdown/code rendering variants in OghmaNotes or similar authenticated Next.js note apps.

## Key lesson

Do not treat implementation success as visual success. Code-block plumbing such as copy buttons, wrap toggles, metadata parsing, alias normalization, or renderer consolidation may be technically useful while being almost invisible in screenshots.

## Better screenshot workflow

1. Pick the right surface:
   - `/syntax-guide` or a dedicated rendered preview page is the best surface for renderer/code-block changes.
   - `/notes/<id>` in Oghma's current single Write surface mostly shows the CodeMirror editor, so renderer changes may not appear there.
   - Chat/message markdown only works if the seeded conversation actually renders an existing message; verify the message is visible, not just the chat empty state.
2. Seed deterministic Markdown with:
   - no-language fences,
   - titled fences such as ```` ```tsx title="src/demo.tsx" ```` ,
   - long lines for wrap controls,
   - unknown languages such as `gitignore`,
   - hostile-looking HTML inside fenced code,
   - tables/tasks/math.
3. Capture full-page screenshots for archival proof, but send **zoomed crops** for decision-making. Full-page composites make subtle code-block differences unreadable in Discord/browser previews.
4. Make crops landscape and large enough to inspect:
   - crop the central content column around the actual code blocks,
   - compare 3-4 variants side-by-side in one row,
   - label each panel clearly,
   - avoid tall vertical composites unless the user explicitly needs page flow.
5. Inspect the screenshots yourself before reporting. Say plainly when differences are not obvious.

## Interpretation pitfalls

- `CodeBlock` UX improvements can be mostly functional rather than visual if controls are tiny, hover-only, or icon-only.
- Renderer consolidation should look identical; report it as architecture/safety cleanup, not a visual improvement.
- Shiki may improve token quality but still look worse overall if its chrome is noisy, repeated controls such as visible `Wrap` buttons clutter reading mode, or it causes a performance drop.
- If the user says they cannot notice a difference, do not defend the branch. Re-crop, re-inspect, and separate "technically useful" from "visibly better".

## Reporting shape

Use blunt categories:

- **Visibly better**: obvious improvement in code block readability/chrome.
- **Functionally better, visually subtle**: useful controls/metadata but screenshots barely change.
- **Architecture only**: no expected visual change.
- **Promising but noisy/heavy**: better rendering engine, worse current UX/perf.

For Oghma specifically, a good next visual pass should include slate code panels matching app tokens, quiet filename/title chrome, compact copy/wrap controls, no repeated text buttons, and measured perf after screenshots look good.
