# Repo-Agent Retrospective Summary Pattern

Use this when Semyon asks what the repo-agent/agent workflow did "last night", "today", or "up to now".

## Goal

Return a concrete operational summary, not a vague description of the scheduler. Include:

- when the workflow ran
- how many sweeps/repo touches occurred
- how many unique repos were covered
- how many code-change PRs/issues/comments were created or updated
- what changed, grouped by repo
- current PR/state verification where practical
- blockers that explain why some repos were only scanned

## Preferred evidence chain

1. Identify the scheduled job from cron metadata, usually the repo-agent full workflow job.
2. Read recent sessions for that job, especially final assistant summaries from each run.
3. Read the latest repo-agent report JSON if present, because it usually has per-repo cards, checks, blockers, and next actions.
4. Verify current GitHub state for named PRs/issues using `gh` before reporting state such as OPEN/CLEAN/UNSTABLE/MERGED.
5. Reconcile all runs into net changes: avoid double-counting a PR that appears in multiple sweeps.

## Summary shape

Start with the top-line count:

```text
Since last night, the workflow ran N full sweeps: HH:MM, HH:MM, HH:MM.
It covered X/Y allowlisted repos each time: Z repo touches total, X unique repos.
Net result: M agent-created PRs are open, all draft/no merges.
```

Then list changes by repo:

```text
### repo
- PR #123 — title — URL
  - what changed
  - checks run / current status
  - blocker if any
```

End with a short prioritized next-action list:

1. clean/easy review/merge candidates
2. PRs needing CI/debugging
3. dirty/diverged worktrees blocking future safe mutations

## Pitfalls

- Do not count every mention of an existing PR as a new change. Count net newly-created or materially-updated artifacts.
- Do not claim a PR is clean/green from an old summary if `gh pr view` or checks now disagree.
- Do not bury the answer in raw logs. Semyon wants a fast operator summary with concrete handles.
- Preserve the human merge gate: summarize draft PRs and checks, but do not imply they were merged unless verified.
