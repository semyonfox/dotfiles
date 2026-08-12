# Markdown CodeBlock polish: T3 Code reference pattern

Session learning from OghmaNotes Markdown/editor work after Semyon asked why the CodeBlock toolbar looked like it had a refresh button.

## Durable lesson

For code block chrome, icon semantics matter as much as highlighting quality. A wrap toggle that looks like refresh/retry makes the block feel broken. If adding per-block controls, copy a proven pattern from a nearby polished app rather than guessing icons.

## T3 Code source reference

Installed source inspected at:

```text
/home/semyon/code/external/t3code/apps/web/src/components/ChatMarkdown.tsx
/home/semyon/code/external/t3code/apps/web/src/index.css
```

Relevant stack in T3 Code web:

```text
react-markdown
remark-gfm
remark-breaks
rehype-raw
rehype-sanitize
@pierre/diffs getSharedHighlighter(...)
Shiki via preferredHighlighter: "shiki-js"
lucide-react icons
```

CodeBlock toolbar imports:

```tsx
import {
  CheckIcon,
  CopyIcon,
  WrapTextIcon,
} from "lucide-react";
```

Toolbar labels and actions:

```tsx
const wrapLabel = wrapped ? "Disable line wrap" : "Wrap lines";
const copyLabel = copied ? "Copied" : "Copy code";
```

Wrap button pattern:

```tsx
<TooltipTrigger
  render={
    <Button
      type="button"
      variant="ghost"
      size="icon-xs"
      className="chat-markdown-chrome-action"
      aria-pressed={wrapped}
      onClick={() => setWrapped((value) => !value)}
      aria-label={wrapLabel}
    />
  }
>
  <WrapTextIcon className="size-3" />
</TooltipTrigger>
<TooltipPopup side="top">{wrapLabel}</TooltipPopup>
```

Highlighting pattern:

```tsx
const highlighter = use(getHighlighterPromise(language));
const highlightedHtml = highlighter.codeToHtml(code, {
  lang: language,
  theme: themeName,
});
```

Highlighter setup:

```tsx
getSharedHighlighter({
  themes: [resolveDiffThemeName("dark"), resolveDiffThemeName("light")],
  langs: [language as SupportedLanguages],
  preferredHighlighter: "shiki-js",
})
```

T3 Code caches both highlighter promises and highlighted HTML with an LRU cache. It avoids caching while a response is streaming.

## UI details to copy/adapt

- Use `WrapTextIcon`, not a circular arrow / refresh-looking icon.
- Use small ghost icon buttons with tooltips, not heavy always-labeled buttons.
- Make Copy visible and obvious; Copy may include text if the surface has room.
- Keep wrap state visually pressed with `aria-pressed` and a subtle active style.
- Consider initializing wrap from a client setting if the product has one.
- Fence titles should show a filename/title when metadata exists; otherwise show a language/file icon or small label.
- Code block container should be quiet: small border radius, subtle border, muted header, transparent highlighted code background.

## Pitfall from Oghma session

Oghma initially used Heroicons `ArrowPathRoundedSquareIcon` for line wrap. Semyon immediately read it as refresh. Do not ship that for wrap. Either use `lucide-react` `WrapTextIcon` or remove the wrap control until a clear icon/menu exists.

## Recommended Oghma adjustment

For OghmaNotes CodeBlock polish:

1. Replace `ArrowPathRoundedSquareIcon` with `WrapTextIcon` from `lucide-react`, or hide wrap in an overflow menu.
2. Prefer `CopyIcon`/`CheckIcon` from the same icon family for visual consistency.
3. Keep the tooltip labels: `Wrap lines`, `Disable line wrap`, `Copy code`, `Copied`.
4. Re-run visual screenshots of `/syntax-guide` and at least one actual rendered note/chat surface; inspect the screenshot yourself before saying it is polished.
