# Frontend UI typography controls

Use this when refining small frontend controls where the user asks for visual polish, typographic hierarchy, or a screenshot-backed iteration.

## Pimp My Type-inspired principles applied

Condensed from Oliver Schöndorfer / Pimp My Type guidance:

- Start from the role of the text. UI labels are **functional text**, so use a compact but readable size, typically ~12–14px, not tiny decorative text.
- Create hierarchy with **contrast and spacing** first. Weight is often the clearest contrast lever; spacing shows what belongs together.
- Use as much variation as necessary and as little as possible. Avoid shouting the same action and format at the same level.
- Functional labels can use a slightly stronger weight and subtle tracking (~0.01em; badges may use more) when small.
- Group related elements tighter, then separate secondary/dropdown content with a clear gap and surface.
- Prefer content structure before decoration: primary action text, secondary format badge, then option title/helper text.

## Split-button pattern for downloads

For a primary download with alternate formats:

1. Use one attached split button: primary anchor/button + compact chevron trigger.
2. Main label should describe the action once, e.g. `Download CV`; show the selected format as a secondary badge (`PDF`, `TEX`).
3. Dropdown should offer only the non-selected option.
4. When selecting the alternate option, update:
   - visible badge
   - `href`
   - `download` filename
   - accessible label (`aria-label`)
   - dropdown option back to the previous format
5. Keep the control visually calm: `text-sm`, medium weight, subtle tracking, muted badges, enough hit area (~44px tall), rounded connected corners.
6. Verify by browser interaction, not just static build: open the dropdown, select the alternate format, then inspect the resulting `href`/`download` values.
7. Send a screenshot of the opened dropdown when the user is aligning on visual direction.

## Pitfalls

- A plain `<select>` beside a download link reads as two separate controls; use a split button when the desired mental model is “one big action with attached alternatives.”
- Avoid labels like `Download PDF` if it makes the file format compete with the action. `Download CV` + `PDF` badge is cleaner.
- If using `innerHTML` to update structured labels, keep the strings internal/static and update the accessible name too.
- Do not let browser-only visual verification replace `pnpm run check` / build verification; do both.