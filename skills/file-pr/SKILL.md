---
name: file-pr
description: "Use when the user asks to file, open, or create a PR."
---

# File PR

Open a concise PR that explains the user-facing problem and why the change matters.

1. Confirm the branch, intended base, and whether a PR already exists. Inspect the diff against the current remote base.
2. Run the relevant checks and collect real verification evidence before filing.
3. Follow the repository’s recent title conventions. Use a short human-readable title that explains the outcome, not an implementation inventory.
4. Start the body with the problem in the user’s terms, then give the small solution summary and verification evidence. Include a reviewable artifact URL only when one exists and helps review.
5. Open a real PR rather than a draft unless the user explicitly requests a draft. If ongoing review/CI monitoring is requested, continue with `babysit-pr`.
6. Add the project’s required model/harness disclosure when its contribution rules call for it.

## Done

Return the PR URL, checks run, and any remaining caveat. Do not merge it unless the user explicitly asks.
