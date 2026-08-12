# Bulk repo-agent PR closer / draft opener

Use this when Semyon asks for a bulk repo-agent PR closer/open-and-close sweep across the repos managed by the recurring full pipeline.

## Workflow

1. Identify the actual recurring repo-agent job first (`cronjob list`) and read its latest durable report (`~/.hermes/repo-agent/reports/latest.json`) so the scope is the managed repo set, not every open PR on the account.
2. Build a live PR inventory with `gh search prs --owner semyonfox --state open` and then re-check each managed candidate with `gh pr view ... --json state,isDraft,mergeStateStatus,statusCheckRollup,files,baseRefName,headRefName` plus `gh pr checks`.
3. Sort candidates into:
   - **ready to merge:** CLEAN, no failing real checks, and either real CI passed or the delta is tiny/inspectable plus locally verified;
   - **verify locally first:** bot-only checks but runtime/config/source changes;
   - **close/supersede:** DIRTY, too broad, stale duplicates, or conflicts after equivalent work landed;
   - **leave alone:** repos outside the managed pipeline scope, archive/session dumps, or dependency noise not requested by the user.
4. For draft PRs that pass verification, mark ready, remove stale `draft:` title prefixes, re-check mergeability, then squash-merge and verify `state=MERGED`, `mergedAt`, and `mergeCommit`.
5. After each merge in a repo, re-check sibling PRs; GitHub may temporarily return `UNKNOWN`/`UNSTABLE` while CodeRabbit or mergeability recomputes. Poll until it returns CLEAN before merging, rather than treating the first status as final.
6. If two stale conflicting PRs contain the same useful idea, do not resolve both directly. Create a fresh branch from current base, salvage the useful delta, run project checks, open a replacement PR that says it supersedes the old ones, close the stale originals with a superseded comment, then merge the replacement only after checks pass.
7. For over-broad dirty drafts, especially large PRs with secret-scan failures, close rather than keep them blocking the pipeline. Preserve the branch if there may be salvageable work, and tell repo-agent/future runs to regenerate smaller focused PRs from current base.
8. After the closer pass, run the repo-agent job once so its durable report/Kanban/project state catches up with the cleaned queue.
9. Final report should separate: merged PRs, fresh replacement PRs opened/merged, closed blockers, left-alone external/dependency PRs, and the final open-PR inventory.

## Useful verification commands

- Browser extension with no package.json: run repo-local smoke scripts directly, e.g. `node scripts/smoke-test.js` and any focused message/unit scripts.
- Minimal package project: `npm test` or `npm run build`, whichever exists and covers the changed surface.
- For stale conflicting PR salvage: use `git merge-tree $(git merge-base origin/main pr-branch) origin/main pr-branch` to see whether conflict is only drift from already-landed work.

## Pitfalls

- Do not merge non-managed archive/session-dump Dependabot PRs just because they appear in the account-wide inventory.
- Do not let bot-only `UNSTABLE` immediately block a verified PR; poll until CodeRabbit/review contexts settle, then merge if CLEAN.
- Do not delete a broad dirty branch while closing the PR if it may contain salvageable work.
- Use `--body-file` for PR bodies/comments that mention backticks, paths, or shell-sensitive text.
