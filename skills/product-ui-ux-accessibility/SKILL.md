---
name: product-ui-ux-accessibility
description: "Use when reviewing product UX, UI polish, layout handoff, accessibility, ARIA, design systems, component docs, theme tokens, or CSS-vs-UI-library choices. General go-to product/UI/UX/accessibility skill; do not load for pure backend work."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]

metadata:
  harness: [hermes]
---

# Product UI UX Accessibility

## Sources

- Obsidian summary: `/home/semyon/obsidian/personal/WebExpo 2026/Summaries/Product UI UX and Accessibility Summary.md`
- `39082683 - The invisible design divide`
- `39082745 - Train your design eye`
- `39082762 - Product experience mapping`
- `39082728 - What I wish someone told me when I first started using ARIA`
- `39082737 - Accessibility by the numbers`
- `39082738 - Designing for everyone`
- `39082735 - Dropping MUI for clean CSS`
- `39082754 - Why adding 45th theme won’t be a problem`

## Core frame

Design is visible decisions that survive implementation, scale through systems, and work for real users. Start with structural sanity before taste debates.

## UI design-eye review

Look first for:

- inconsistent spacing;
- ambiguous grouping;
- weak alignment;
- too many colors;
- low contrast;
- unbalanced visual weight;
- labels far from controls;
- repeated components with inconsistent rhythm.

Every padding, color, and placement is already a design choice.

## Layout handoff

Static Figma pixels are not enough. Specify:

- what stretches;
- what wraps;
- what truncates, ideally avoiding truncating important text;
- min/max widths;
- empty/error/loading states;
- responsive breakpoints or container-query rules.

Remember:

- Flexbox is one-dimensional.
- CSS Grid is two-dimensional.
- Container queries respond to parent containers.
- `clamp()` is useful for fluid type/spacing.
- Browser behavior is the source of truth.

## Accessibility priorities

Prioritize actual barriers over fake 100% scores:

- CAPTCHA/access barriers;
- inaccessible interactive elements;
- ambiguous links/buttons;
- missing labels;
- low contrast;
- keyboard traps/lack of keyboard support;
- meaningful missing alt text;
- missing language identification.

## ARIA rules

Native HTML first.

- Prefer real `<button>`, `<a>`, `<nav>`, `<main>`, headings, lists, and forms.
- ARIA fills semantic gaps; it does not redeem div soup.
- Accessible name + role + state should communicate what something is and what happens.
- Do not put `aria-hidden="true"` or `role="presentation"` on focusable elements.
- Avoid redundant labels like `aria-label="Close button"` on a button.

## Design systems

Component docs should include:

- usage guidance;
- keyboard behavior;
- native/ARIA semantics;
- focus states;
- contrast requirements;
- text resizing behavior;
- do/don’t examples;
- tested assistive-tech expectations where relevant.

Token systems:

- separate raw/core values from semantic tokens;
- components use semantic tokens;
- modes/themes resolve through token layers;
- contrast and combinations are tested;
- adding theme 45 should be boring.

## UI library / CSS decision

A UI library is fine when it accelerates safely. It becomes a ceiling when customization, bundle/perf, inconsistent overrides, or design-system ownership get worse.

Clean controlled CSS is harder at the start but often more predictable if the team aligns patterns.

## Icon and micro-control semantics

For compact chrome such as code-block toolbars, icon choice is product language, not decoration. If a button toggles wrapping, use a wrap-lines icon and an explicit tooltip/accessible label; do not use circular-arrow/refresh/retry icons that imply reload. Prefer small ghost icon buttons for secondary per-block actions, with `aria-pressed` for toggles and labels such as `Wrap lines`, `Disable line wrap`, `Copy code`, and `Copied`. If the correct icon is unavailable, hide the control behind a menu or omit it rather than shipping an ambiguous always-visible button.

## Review checklist

- [ ] Spacing and grouping are clear.
- [ ] Browser layout matches intent across widths.
- [ ] Native HTML before ARIA.
- [ ] Keyboard and focus states work.
- [ ] Labels/links/buttons are unambiguous.
- [ ] Icons match the action semantics and are backed by tooltip/accessible labels when compact.
- [ ] Contrast and text resizing are tested.
- [ ] Component docs include accessibility behavior.
- [ ] Tokens are semantic, not random hex soup.
- [ ] UI library use is intentional, not dependency Stockholm syndrome.

## Visual review with Gemini/agy

When reviewing screenshots or live pages where visual fidelity matters, use Antigravity CLI/Gemini as a headless visual-description worker when available, then apply product judgement yourself. Call `agy` directly like `claude -p`; do not create wrapper scripts unless Semyon asks.

```bash
IMAGE=/path/to/screenshot.png
AGY_MODEL="Gemini 3.5 Flash (Low)"
agy --model "$AGY_MODEL" --mode plan --add-dir "$(dirname "$IMAGE")" --print-timeout 5m -p "Use Gemini vision on this image. Return visible observations only for another model: layout, exact text, colours, spacing, hierarchy, component states, icons, anomalies, clipping, unreadable text, contrast issues, accessibility risks visible from the screenshot, and confidence. Separate observations from guesses. Do not recommend redesigns or make final taste/product decisions: $IMAGE"
```

Use `Gemini 3.5 Flash (Medium/High)` for dense UI, small text, diagrams, or multi-image comparisons; keep Pro for rare cases where visual extraction itself needs deeper reasoning. Treat Gemini as the eyes: good for layout/a11y inventory and screenshot-specific misses. Claude/Fable/Opus/Codex remain better for final taste, copy, and implementation judgement. Strip speculative Gemini recommendations before using its report; preserve concrete pixel observations only.

## Visual comparison discipline

When reviewing UI variants, do not rely on full-page screenshots if the change is small. Produce focused crops/zooms around the changed component, inspect them directly, and tell the user whether the improvement is actually visible.

For Semyon's visual-review workflow, use Antigravity CLI/Gemini as a headless vision worker when image fidelity matters, then synthesize the result yourself. Do **not** create wrapper scripts or route this through Hermes provider config unless explicitly asked. Call `agy` directly, Claude `-p` style, and vary the model/thinking level per image complexity:

```bash
IMAGE=/path/to/screenshot.png
AGY_MODEL="Gemini 3.5 Flash (Low)"  # Medium/High for dense UI, small text, diagrams, multi-image comparison
agy --model "$AGY_MODEL" --mode plan --add-dir "$(dirname "$IMAGE")" --print-timeout 5m -p "Use Gemini vision on this image. Return visible observations only for another model: layout, exact text, colours, spacing, hierarchy, component states, icons, anomalies, clipping, unreadable text, contrast issues, accessibility risks visible from the screenshot, and confidence. Separate observations from guesses. Do not recommend redesigns or make final taste/product decisions: $IMAGE"
```

Separate:

- **visible product polish** — spacing, hierarchy, typography, interaction chrome, clarity;
- **functional plumbing** — copy buttons, metadata parsing, shared components, architecture cleanup;
- **technical quality** — better libraries/highlighters, safety, bundle/perf tradeoffs.

If the user says they cannot see the difference, treat that as a product signal, not a communication problem: the change may be too subtle, noisy, or aimed at the wrong surface. Revise the screenshots and analysis before recommending a direction.
