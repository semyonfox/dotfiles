---
name: frontend-product-implementation
description: "Use when implement, verify, and hand off scoped product-facing frontend changes without broadening visual feedback or leaving backend form contracts inconsistent."
version: 1.0.0

metadata:
  harness: [hermes]
---

# Frontend Product Implementation

Use for implementing concrete public-site, app-shell, typography, header, theme, onboarding, and form changes where user feedback must become a verified, reviewable code change.

## Principles

- Treat the user’s named UI surface as the scope boundary. If they say “editor headings”, do not alter global heading tokens, generic body colour, or unrelated screens.
- Preserve intentional colour: status meaning, calls to action, links, syntax highlighting, and user-authored colour should not be flattened by a readability fix.
- Prefer a single global rule only when the feedback truly names a system-wide property, such as the minimum normal UI text size.
- When a visual request appears inconsistent across themes, inspect implementation and rendered/computed styles before changing layout. Static asset colours often explain a light/dark discrepancy.

## Workflow

### 1. Map the affected surface

1. Read the shared component, route, and relevant theme tokens/styles.
2. Search for all uses of the named form field, logo asset, or typography class before editing.
3. Identify whether the defect is local styling, a hard-coded asset colour, responsive visibility, or a shared token.
4. State the exact intended scope in the commit/PR description.

### 2. Apply narrow visual fixes

- For a static logo invisible in one theme, adapt that logo in the affected theme rather than changing unrelated text colours. Use a semantic class when possible; a narrowly targeted asset selector is acceptable when all uses share the same intended treatment.
- If mobile needs product identity, make the product label visible in the mobile header while retaining the established icon and menu touch target.
- For editor typography, patch the editor heading rules directly. Use the standard editor text token so dark and light modes both remain readable.
- Do not use a global `color: white` / semantic-token override to solve a local editor-heading request.

### 3. Simplify public forms end to end

Keep a first-contact form short but useful: normally name, email, concise reason, and message. A public form should not collect surname, phone, institution, or role merely because a lead table has columns for them.

For every removed field, trace and update:

1. Client component, browser validation, labels, and client analytics payload.
2. API schema and server validation.
3. Database insert and constraints. Add a forward-only migration if a formerly required column will now be absent; never rewrite existing leads just to support a shorter new form.
4. Notification email and reply handling.
5. Server-side analytics allowlist and tests.

Do not leave dead properties or stale email labels after field removal.

### 4. Verify visually and functionally

1. Run focused tests for API/form/analytics contracts.
2. Run lint, typecheck, full relevant tests, and production build.
3. Start a controlled local or mock instance and inspect the actual requested theme and viewport in a browser.
4. Confirm computed theme class and crucial properties (e.g. static logo visibility/filter), then confirm the accessible form field list matches the intended compact contract.
5. Stop any test server started for this verification.

### 5. GitHub handoff

- Commit only intended source, migration, and test files; exclude generated build references and ignored local mock env files.
- Push the isolated branch and open a draft PR when the user asked to implement a tracked issue.
- Link the issue in the PR. Leave it open until merge unless the repository explicitly uses branch completion as its closing convention; an implementation comment can document the draft PR meanwhile.

## Pitfalls

- **Scope creep after ambiguous visual wording:** if a phrase could refer to a screenshot surface or the whole system, infer from the nearest named component and keep the patch local. If the user corrects scope, revert the broad change cleanly rather than layering overrides on top.
- **SVGs that are invisible only in light mode:** inspect the SVG’s own `fill`/`style` before redesigning the header. A white hard-coded asset needs a light-theme treatment.
- **Form UI-only simplification:** deleting fields only in JSX can leave API validation, NOT NULL database constraints, notifications, and aggregate analytics inconsistent.
- **Premature issue closure:** tests and a local commit prove implementation, not deployment/merge.

## Verification checklist

- [ ] Named visual surface, responsive scope, and theme scope are explicit.
- [ ] Unrelated global colours and intentional semantics are unchanged.
- [ ] Every removed public field was traced through UI, API, DB, notifications, analytics, and tests.
- [ ] Targeted tests, full tests, lint, typecheck, and production build passed.
- [ ] Browser verification covers the requested theme and actual accessible UI.
- [ ] Branch/PR/issue status accurately reflects what is implemented versus merged.

See `references/public-ui-feedback-and-form-simplification.md` for the compact field-removal and light/dark asset checklist.
