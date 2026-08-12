# Frontend split-button UI iteration

Use for compact download/action controls where a primary button has an attached chevron/dropdown for alternate formats or modes.

## Pattern

- Treat it as a **split button**:
  - Main button performs the selected/primary action.
  - Chevron opens alternate options.
  - Selecting an alternate usually changes the selected action; it should not auto-fire unless the product explicitly wants immediate menu actions.
- For download format selectors, prefer the safer two-step flow: choose format in dropdown, then press the main Download button. This avoids surprise downloads when a user is only inspecting options.
- Dropdown options should show the **non-selected** option(s), not duplicate the active one.

## Compactness and visual sizing

- Keep dropdown width equal to the whole split-button group; avoid menus wider than the trigger unless the option text genuinely requires it.
- Keep dropdown row height equal to the main button height for one-option compact menus.
- Avoid explanatory second lines/tooltips in expert-only format options like TeX; users who need TeX know to look for it.
- If a user asks for “like the original size,” scale toward the existing button rhythm before inventing a larger component.

## Hover states

- If the split button is visually connected, hover/focus affordance should feel connected too.
- Avoid a left-only hover that appears blocked by the chevron segment. Use a wrapper/group hover for shared border/background treatment, while still allowing the chevron icon itself to brighten independently.

## Typography notes

- For compact functional text, use small but readable type, medium weight, and subtle tracking.
- Keep the action label short (`Download`) and use a small uppercase badge for the selected format (`PDF`, `TEX`) when space is tight.

## Verification

- Measure button group width/height, dropdown width, and option row height in browser automation when possible.
- Capture screenshots for both active states when the UI toggles selected option (e.g. PDF selected and TeX selected).
- Verify the actual href/download attributes after changing the selected format.
