---
name: babysit-pr
description: "Use when the user asks to monitor, watch, or babysit a PR."
metadata:
  harness: [claude, codex]
---

# Babysit PR

Monitor an existing PR through review and CI; do not turn it into different work.

1. Read the goal, current diff, latest push SHA, review comments, checks, and merge state.
2. Poll available PR/check tools for comments or statuses newer than that push.
3. Verify each finding against the current source and goal before editing. Fix real defects and failing project checks; distinguish infrastructure flakes from repository failures.
4. Refresh from the base branch when needed. If another PR supersedes this one, report it and stop unless the user authorises closing it.
5. Clearly reply when rejecting a false positive. When commenting for the user, identify the harness/model if the platform permits it.
6. Keep fixes within the original goal: address real shortcomings, reject scope creep.

## Done

Stop when the PR is green and ready for user review/merge, or report the exact blocker. Never merge without explicit user instruction.
