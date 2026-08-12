# Frontend split-button dropdown pattern

Use this when a user asks for “one big button with a dropdown attached”, especially for choosing between a default action and alternate download/export formats.

## Pattern

- Prefer a **split button** over a separate `<select>` plus action button when there is one dominant/default action.
- The main segment is the immediate action, e.g. `Download PDF`.
- The attached chevron segment opens a small menu.
- The menu should show only the alternate/non-selected option when there are two choices, e.g. when PDF is active, show `TeX source`; when TeX is active, show `PDF`.
- Selecting an alternate updates:
  - main button label
  - main button `href` / action target
  - download filename or equivalent action metadata
  - dropdown item back to the other option
- Keep the two segments visually attached: left segment rounded-left, right segment rounded-right, shared border, no gap.

## Accessibility / behaviour checklist

- Chevron button is `type="button"`.
- Use `aria-label` for the chevron action, e.g. `Choose CV format`.
- Maintain `aria-expanded` as the menu opens/closes.
- Close on outside click and Escape.
- Avoid nesting buttons inside anchors or using a form unless submission is actually needed.

## Verification

For UI-alignment tasks, don’t just describe the design. Implement the smallest working version, run the project checks/build, open it locally, interact with the control, and capture a screenshot with the dropdown open so the user can confirm the visual direction.
