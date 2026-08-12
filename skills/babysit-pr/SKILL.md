---
name: babysit-pr
description: "Use when the user asks to monitor, watch, or babysit a PR."
metadata:
  harness: [claude, codex]
---

# Babysit PR

Monitor an existing PR through review and CI without turning it into a different piece of work.

1. Read the original goal, current diff, latest push SHA, review comments, checks, and merge state.
2. Poll or use the available PR/check tools for comments and statuses newer than the latest push.
3. Verify every review finding against the current source and the original goal before editing. Fix real defects and failing project checks; distinguish infrastructure flakes from repository failures.
4. Keep the branch fresh with its base branch when needed. If another PR supersedes it, report that and stop unless the user authorises closing it.
5. Reply clearly when dismissing a false-positive review finding. If commenting as an agent on the user's behalf, identify the harness/model where the platform permits it.
6. Do not let review feedback expand the PR beyond the user’s original goal. Address real shortcomings; reject scope creep.

## Done

Stop when the PR is green and ready for the user's review/merge, or report the exact remaining blocker. Do not merge unless the user explicitly asks.
