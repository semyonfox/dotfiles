# Compact checklist: theme visibility and first-contact forms

## Theme-specific brand visibility

1. Compare the same public header/footer in light and dark mode.
2. Inspect the rendered `<img>`/SVG source and computed `filter`, `fill`, and dimensions.
3. If the asset itself uses a hard-coded white fill, give only that asset a light-theme adaptation. Do not compensate by making all text white or changing the background system.
4. Confirm mobile does not hide the product label when the issue is recognisability rather than icon design.

## A four-field first-contact baseline

A compact but useful first-contact flow can be:

- first name;
- email;
- a controlled reason selector;
- message.

Before removing other fields, inspect their schema/database requirements. If the database requires a value no longer collected, add a forward-only migration to make it nullable or persist a documented non-PII compatible value only where that is semantically honest. Existing records must remain unchanged.

## Evidence to capture

- targeted API + analytics tests prove the new submission contract;
- browser accessibility tree confirms the visible field list rather than just source-code intent;
- computed styles prove the target theme’s brand mark is visible;
- lint, typecheck, full tests, and production build provide the regression gate.

## Migration and public-contract traps

- Inspect the migration runner before naming a new schema migration. If it records only the numeric filename prefix, that prefix must be new and unique: a duplicate can be silently skipped by `--all`, leaving a new API insert incompatible with the live `NOT NULL` schema.
- Add a focused regression test asserting the new migration filename exists and no other migration shares its numeric prefix. Mocked API tests alone cannot prove the migration ran.
- Keep advertised contact reasons selectable. Simplifying fields must not remove a reason (for example, billing) that public copy still promises to handle.
- After merging to a deployment branch, distinguish a healthy existing URL from the new build being live. Verify the changed form/brand behaviour on the deployed site, not only HTTP health, before saying deployment completed.
