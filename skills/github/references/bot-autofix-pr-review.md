# Bot/autofix PR review

Use when reviewing CodeRabbit, Copilot, Dependabot, Renovate, or other bot-authored autofix PRs.

## Principles

- Treat bot PRs as suggestions, not authority.
- Do not auto-merge a bot PR just because it is small or labelled as an autofix.
- Inspect the actual changed behavior and current-base context; bot branches often go stale and fail for unrelated reasons.
- If the bot found a real issue but the patch is unsafe, close the bot PR and open a human-authored salvage PR.

## What to check

1. **CI state:** distinguish real test/build failures from stale branch-naming or transient E2E setup failures.
2. **Current-base drift:** compare the bot diff against current `origin/<base>`; the issue may already be fixed differently.
3. **Environment/config names:** bot fixes often invent env vars. Verify they exist in templates, deployment docs, Jenkins/env files, and runtime code before accepting config/security changes.
4. **Scope bundling:** reject PRs that mix unrelated concerns such as CSP policy, UX navigation behavior, and test typing in one autofix.
5. **Behavior changes:** small diffs like redirecting instead of preserving fallback UI are product decisions, not mechanical fixes.

## Common salvage patterns

- **CSP/security headers:** design deliberately using existing/documented env vars; add tests/assertions for generated policy. Avoid blindly narrowing `connect-src` to `self` when external storage/API/WebSocket origins are required.
- **Test mock typing:** safe to salvage into a small cleanup PR if it addresses actual `tsc --noEmit` errors.
- **Layout/navigation fallback:** decide desired offline/network/404 UX first; do not accept unexplained bot behavior changes.

## Reporting

Recommendation should be one of:

- merge as-is
- close as stale/unsafe
- salvage specific pieces into a new PR

Include evidence: changed files, failed checks, real current-base issue, and why the bot patch is or is not safe.