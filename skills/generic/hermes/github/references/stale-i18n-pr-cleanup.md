# Stale i18n PR cleanup and safe replacement

Use this when an old translation PR is conflicted/stale or machine-generated.

## Core rule

Do not merge a stale machine-translation branch directly just because checks once passed. Locale files are high-risk for silent UI corruption: a stale branch can drop newer keys, break interpolation placeholders, or turn internal i18n keys into user-visible text.

## Review sequence

1. Compare keyset size and exact keys between current base and the PR branch for every locale.
2. Check placeholder parity against the base locale (`{count}`, `{summary}`, `{correct}`, `{total}`, etc.).
3. Detect key-like values in translated strings, especially values that look like:
   - `foo.bar.baz`
   - `foo.bar.baz_one`
   - `foo.bar.baz_other`
   - `Some.Namespace.Key_one`
4. Check plural/suffix artifacts. Machine translation often preserves or mangles `_one` / `_other` instead of translating the phrase.
5. Prefer a fresh branch from current base that preserves the current keyset and fixes only unsafe values.
6. Close the stale original PR as superseded once the replacement exists.

## Safe cleanup policy

When a translation is clearly corrupt, prefer a safe English fallback over broken translated UI. English fallback is visible but understandable; key-like garbage leaks internals and looks broken.

A replacement PR should state this tradeoff clearly: it is a safety cleanup, not a full native-speaker translation pass.

## Verification

Run the project i18n audit/scan. If the existing audit only checks keysets/placeholders, add an ad-hoc invariant check for:

- missing/extra keys per locale
- placeholder mismatch vs base locale
- key-like translated values
- unsafe `_one` / `_other` suffix artifacts in values

Known warning patterns that may be acceptable if documented:

- `same-as-en` entries after replacing unsafe translations with English fallbacks
- dynamic-key warnings from non-literal `t(...)` calls
- static parser unused-key warnings when runtime keys are dynamic

## Reporting

For Semyon, summarize:

- whether the old PR is mergeable or should be closed
- whether a replacement branch/PR was created
- what was intentionally preserved, translated, or reverted to English fallback
- exact verification commands and remaining warnings
