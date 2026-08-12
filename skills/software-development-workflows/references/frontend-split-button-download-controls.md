# Frontend split-button download controls

Use for compact download controls where one primary file type is common and alternate formats exist (e.g. portfolio CV PDF vs TeX).

## UX pattern

- Prefer a **split button**: main button performs the selected/default action; attached chevron opens alternate formats.
- The dropdown should **select/switch the alternate format**, not auto-download, when the alternate is secondary or expert-oriented. This avoids surprising downloads when the user is only inspecting options.
- Only the main button downloads the currently selected file type.
- Dropdown should show the **non-selected option only** when there are two formats.

## Visual/typography guidance

- Keep dropdown width aligned to the button group; do not let the menu become wider than the button unless there is a strong content reason.
- For small controls, keep dropdown rows **one line** and the **same height as the main button**.
- Avoid explanatory secondary text/tooltips for obvious expert formats (e.g. TeX); people who need it know to look for it.
- Use functional text rules: readable 12–14px scale, medium weight, tiny tracking for badges, and clear contrast/spacing without overbuilding the component.

## Verification

- Test both selected states with the dropdown open.
- Verify the main button `href`, `download`, and accessible label update when switching formats.
- Verify dropdown row height equals the button height and menu width equals the button group width in browser measurements.
