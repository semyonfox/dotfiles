---
name: personal-web-monitoring
description: "Use when monitoring personal web pages without acting."
version: 1.0.0
created_by: agent

metadata:
  harness: [hermes]
---

# Personal web monitoring

Use this workflow when Semyon asks to be notified when an official webpage, online form, availability listing, or result page changes, while reserving any submission, purchase, consent, contact, or other consequential action for explicit approval.

## Safety boundary

1. Establish the monitored condition precisely. Prefer a structural signal (a labelled input, button state, result row, or official status text) over loose keyword matching.
2. Separate observation from action. Filling a form, ticking consent, submitting, buying, contacting an organiser, or publishing is out of scope unless Semyon explicitly authorises it at that time.
3. State the no-action guarantee in the confirmation: what will be watched, what triggers the alert, and what will not be done.
4. Keep sensitive values out of watcher output and scripts where they are not required. A watcher should check the page structure, not retain form content.

## Before scheduling

- Recover the exact official URL from direct context or session history; do not guess from an organisation name.
- Inspect the current live page and record the baseline condition. For forms, enumerate the actual fields/labels rather than relying on explanatory copy.
- Inspect existing cron jobs before creating or modifying one. Never guess job IDs.
- Pick the lightest reliable mechanism: a no-agent script for a deterministic condition; an agent job only when interpreting the page genuinely requires reasoning.

## One-time deterministic watcher

For a simple HTML condition, create a small script under `~/.hermes/scripts/` that:

1. fetches the official URL with a timeout and an ordinary User-Agent;
2. tests for a specific structural signal (for example a `Week 6 code` field label), not general prose that could create false positives;
3. writes a minimal local sentinel only after the condition is true;
4. emits a concise alert only if the sentinel did not already exist; otherwise emits nothing;
5. exits non-zero on fetch failure so the scheduler reports a broken watcher rather than silently claiming the page is unchanged.

Schedule it with `no_agent=true`: empty stdout is deliberately silent, and the first non-empty stdout is the user-facing alert. Use a finite repeat count or a deadline-aware expiry for time-limited monitors. Run the script manually, then trigger the cron job once to verify the healthy-silent path.

## Reporting

On setup, report only: current baseline, frequency, trigger condition, and no-action boundary. On a trigger, state that the condition changed and explicitly say no external action was taken. Do not repeat alerts after the sentinel is present.

## Pitfalls

- A page that says “all six codes earn a bonus” does **not** prove that a sixth entry field exists; inspect inputs and labels.
- Avoid embedding a user’s filled values, email address, or credentials in the watcher.
- Do not alert repeatedly just because the condition persists after the first successful detection.
- If the website is authenticated or JavaScript-rendered, use a browser-capable approach and verify it can observe the relevant UI before promising monitoring.
- Browser element references belong to one live browser session. Do not batch dependent browser typing/clicking in parallel: navigate, then interact sequentially, refreshing the snapshot after any stale-reference error.
- After an explicitly authorised submission, verify a server-side success/confirmation message. A UI click alone is not proof that an entry was received; if ordinary clicking leaves a valid form unchanged, use the page's normal `form.requestSubmit()` path and then inspect the returned confirmation.

## Reference

See [references/businesspost-sixth-field.md](references/businesspost-sixth-field.md) for a concrete form-field watcher pattern.