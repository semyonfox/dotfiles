---
name: typography-ux
description: "Use when reviewing or designing typography, readable text, font choices, visual hierarchy, contrast, responsive type, or UI text readability. General go-to typography skill; do not load for unrelated coding tasks."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]

metadata:
  harness: [hermes]
---

# Typography UX

## Sources

- Obsidian summary: `/home/semyon/obsidian/personal/WebExpo 2026/Summaries/Typography UX Summary.md`
- Conference note: `39082765 - How bad typography kills UX` by Oliver Schöndorfer
- Adjacent note: `39082683 - The invisible design divide`
- External authority: Pimp my Type by Oliver Schöndorfer
  - `https://pimpmytype.com/start`
  - `https://pimpmytype.com/font-size/`
  - `https://pimpmytype.com/line-length-line-height/`
  - `https://pimpmytype.com/hierarchy/`
  - `https://pimpmytype.com/color-contrast/`

## Core frame

Typography is interface mechanics, not decoration. It controls readability, scanning, hierarchy, trust, and accessibility.

Good typography is quiet. Bad typography makes users work: they scroll for contrast, lose hierarchy, skip copy, or misread controls.

## Baseline numbers

Use as starting points, then judge the actual typeface and layout.

| Area | Starting point |
| --- | --- |
| Body text | `16px` / `1rem` minimum; often larger on desktop |
| Desktop long reading | often `18–24px` depending on design |
| H1/display | around `32px` mobile, `40–64px` desktop |
| Functional UI text | `12–14px`, with stronger weight/tracking if small |
| Reading measure | `60–80` characters per line |
| CSS measure shortcut | `max-width: 30rem–40rem` |
| Body line-height | around `1.5–1.6` for long reading |
| Heading line-height | tighter, often `1.1–1.25` |
| Normal text contrast | WCAG AA `4.5:1` |
| Large/bold text contrast | WCAG AA `3:1` |
| UI control boundary | aim for `3:1` against adjacent background when needed |

## Review workflow

1. **Start with body text** — readable body first, brand theatrics second.
2. **Tune the holy trinity together** — font size, line length, line height.
3. **Check typographic color** — paragraph density should feel inviting, not brick-like or scattered.
4. **Build hierarchy with contrast and spacing** — weight and grouping often beat random size jumps.
5. **Verify contrast** — text, icons, controls, boundaries, focus states, disabled states, dark mode.
6. **Check responsive behavior** — real browser, real containers, not only Figma.
7. **Test fallbacks** — language/script support and platform fallback fonts can wreck density.
8. **For deployed Markdown editors, inspect the authenticated live editor DOM when authorized** — public docs and local branches can be stale compared with the real CodeMirror surface. See `references/live-markdown-editor-typography-audits.md`.

### Markdown editor audits

For Markdown editors, all-in-one writing surfaces, rendered preview/source splits, CodeMirror themes, or semantic Markdown styling, use `references/markdown-editor-typography-audits.md`. Key points: confirm whether the product is truly one surface or still a Source/Read split, inspect both source and rendered Markdown surfaces, compare body/heading math across modes, keep prose readable before styling syntax, and calculate light/dark contrast from actual app tokens. Treat small status labels and syntax comments as normal text unless they are genuinely decorative.

### Markdown/editor typography audits

When auditing Markdown editors or rendered Markdown, inspect the editable source surface and the rendered/read surface as one typography system. Compare body/heading/code/list/blockquote sizes, line-height, spacing rhythm, measure, and semantic hierarchy across both surfaces. Record exact files/selectors/tokens and concrete CSS values; if the user asks for an audit, do not edit files unless explicitly requested or a trivially safe patch is clearly separated from the report.

For CodeMirror-backed writing surfaces, check whether the product promise matches the implementation: an “all-in-one” or Notion-like editor should not silently remain a raw `Source / Read` split with full-monospace prose unless that is an accepted transitional compromise. Verify computed body and heading sizes because `em`-based editor headings can drift from `rem`-based rendered headings when the editor base font is smaller than 16px.

Detailed checklist and OghmaNotes-specific selectors/tokens: `references/markdown-editor-typography-audits.md`.

## Font choice and pairing

- Choose a typeface for function: body readability, x-height, weights, italics, numerals, symbols, language support.
- Ask whether a second typeface is actually needed.
- Easy pairing wins: use a family/superfamily, or a deliberately contrasting display/body pair.
- Avoid two typefaces that are almost the same but not quite; it looks accidental.

## Red flags

- Body text below `16px` for substantial reading.
- Full-width paragraphs on desktop.
- No clear primary/secondary hierarchy.
- Labels and controls separated by equal spacing to unrelated items.
- Fancy low-contrast text.
- Button text passes contrast but button boundary disappears.
- Figma layout looks good but browser layout wraps/truncates badly.
- Important text is truncated by default.
- In all-in-one Markdown editors, syntax markers are hidden but the semantic block styling is missing — e.g. `>` disappears yet the quote has no border/background, or fenced code has syntax colors but no code-block chrome.
- Heading/list/link/emphasis markers are inconsistently rendered: some raw punctuation remains visually loud while other Markdown syntax is hidden.

## Output style when using this skill

Give practical fixes, not vague “improve visual hierarchy”. Include concrete CSS-ish values where useful.

Example:

```css
.article {
  font-size: clamp(1rem, 0.95rem + 0.25vw, 1.2rem);
  line-height: 1.55;
  max-width: 38rem;
}

h1 {
  font-size: clamp(2rem, 1.4rem + 3vw, 4rem);
  line-height: 1.1;
}
```

## Quick checklist

- [ ] Body readable at real device distance.
- [ ] Measure constrained.
- [ ] Line-height matches measure and font.
- [ ] Hierarchy visible when squinting.
- [ ] Related items are closer than unrelated items.
- [ ] Contrast passes and feels usable.
- [ ] Type survives responsive layouts and fallbacks.
