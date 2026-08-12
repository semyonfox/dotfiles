# Repo-agent recurring sweep operations

Use this reference when a recurring autonomous repo sweep is creating or reviewing GitHub work across several repos.

## Branch naming noise

If safe automation branches such as `agent/<topic>-<timestamp>` fail a branch-naming workflow, treat that as status noise unless the workflow is actually required by branch protection. Prefer a small isolated PR to delete or relax the workflow rather than renaming durable agent branches. Example fix options:

```diff
- VALID_PATTERNS="^(feature|bugfix|hotfix|chore|docs|refactor|test|release|feat|fix)\/[a-z0-9\-]+$"
+ VALID_PATTERNS="^(agent|feature|bugfix|hotfix|chore|docs|refactor|test|release|feat|fix)\/[a-z0-9\-]+$"
```

or delete the workflow if it is pure bikeshed CI and not a protected required check.

## Existing PRs and conflicts

For conflicted PRs, do not say only “merge conflict”. Identify:

- PR number, title, branch, base, merge state
- exact conflicted files from `git merge-tree --write-tree --messages --name-only <base> <head>` or equivalent
- whether the PR branch, base branch, or a selective cherry-pick should win
- a small concrete before/after example the user can inspect in chat

Default recommendation for old broad PRs: keep current base branch as truth, then reapply useful pieces in a fresh branch if still valuable. Translation/file-regeneration PRs usually need regeneration from current base rather than conflict-marker surgery.

## Dirty local state before agents mutate

Classify dirty repos into:

1. real dev work: source, tests, docs, scripts worth preserving
2. generated noise: caches, build output, pycache, IDE churn
3. local data/content: sqlite DBs, PDFs, imported assets, large binaries needing human approval
4. local commits ahead of remote

For mixed state, preserve real dev work on a `wip/<topic>` branch or isolated worktree before cleanup. Do not commit local databases or large content imports just to get the tree clean.

## AI review mining

Do not treat CodeRabbit/Copilot/Codex/Claude reviews as mandatory gates, but do mine them for useful findings. Fetch PR reviews, review comments, issue comments, and status contexts. Classify findings as actionable, optional/nit, stale, or skipped/no-review. If actionable and still valid against the current diff, fix, open/link an issue, or report human action needed.

## Superseded PR cleanup

After a salvage/replacement PR merges, close the old PR with a short comment naming the replacement and what was intentionally skipped. Delete the old branch when it belongs to the same repo and is not needed for audit/history. If `gh pr merge --delete-branch` or `git branch -d` fails because a local worktree still owns the branch, remove the worktree first, then delete the local branch and remote branch. Verify remote cleanup with:

```bash
git ls-remote --heads origin <branch-name>
```

No output means the branch is gone.

## Minimum useful recurring-run outcome

A recurring repo-agent pass should produce at least one concrete outcome or an explicit no-op reason:

- draft PR opened/updated
- concrete issue opened
- blocker with exact next decision/command
- cleanup action taken/proposed
- `no safe work found` with evidence

Avoid letting repeated `NO_ACTION` reviews hide the fact that the agent failed to mine new work.