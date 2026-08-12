# CodeMirror Markdown heading sizing pitfall

Use this when changing heading typography in the OghmaNotes CodeMirror-backed Markdown editor, especially after the inactive Markdown syntax/rendering migration.

## What went wrong

Changing theme selectors such as `.cm-header-1`, `.cm-header-2`, and `.cm-header-3` may not visibly affect the editor. CodeMirror 6 can render Markdown headings using generated highlight classes (`ͼp`, `ͼq`, `ͼr`, etc.) from `HighlightStyle`, not the obvious `.cm-header-*` selectors.

In OghmaNotes, the earlier patch made the selector rules larger but Semyon did not notice a change because the visible text was styled by generated token classes. The fix was to put the font-size/line-height/letter-spacing directly on the `HighlightStyle.define()` entries for `t.heading1`, `t.heading2`, and `t.heading3`.

## Correct pattern

In `src/components/editor/write-editor-theme.ts`, keep selector styles for fallback/container behavior, but apply the real visible heading scale to the highlight tokens:

```ts
const oghmaHighlightStyle = HighlightStyle.define([
  {
    tag: t.heading1,
    color: "var(--md-heading-1)",
    fontSize: "2.65em",
    fontWeight: "750",
    lineHeight: "1.08",
    letterSpacing: "-0.025em",
  },
  {
    tag: t.heading2,
    color: "var(--md-heading-2)",
    fontSize: "2.05em",
    fontWeight: "700",
    lineHeight: "1.12",
    letterSpacing: "-0.025em",
  },
  {
    tag: t.heading3,
    color: "var(--md-heading-3)",
    fontSize: "1.55em",
    fontWeight: "650",
    lineHeight: "1.2",
    letterSpacing: "-0.025em",
  },
]);
```

## Verification recipe

1. Do not trust a diff or a global CSS grep. Mount/render the editor or inspect the live browser DOM.
2. Confirm actual heading spans have generated classes, not just `.cm-header-*`.
3. Confirm injected styles for those generated classes include the desired `font-size`, e.g.:

```css
.ͼp { font-size: 2.65em; }
.ͼq { font-size: 2.05em; }
.ͼr { font-size: 1.55em; }
```

4. For deploy checks, verify both Jenkins and the running container/image, then inspect the built bundle inside the container if the public page does not obviously show the change.

## User-facing pitfall

If Semyon says he cannot see a typography change, assume the first patch may have hit the wrong styling layer. Dig into computed/generated CodeMirror token classes before insisting the change deployed.