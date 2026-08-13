---
name: ship-changes
description: "Use when the user asks to commit, push, open or update a PR, repair CI, mark ready, or merge. Validate and deliver only the authorised stage and prerequisites."

metadata:
  harness: [claude, codex]
---

# Ship changes

Treat a request to commit, push, open a PR, ship, land, finish, or merge as authority for the named stage and its necessary predecessors—not unrelated external actions.

## prepare

1. Inspect the worktree, current branch, remotes, existing PR, and unrelated changes.
2. Select the first existing remote base: `dev`, `develop`, `testing`, `staging`, `main`, `master`, then the remote default. An explicitly named base wins.
3. Never implement directly on the base branch. Create or reuse a scoped branch; use a worktree if switching would disturb the user or another writer.
4. Discover repository-provided format, lint, typecheck, test, and build commands. Run the checks proportionate to the change before committing.
5. Review the staged diff and commit intentionally. Never mention AI or co-authorship.

## pull request and green loop

1. Push the scoped branch and open or update a draft PR against the selected base.
2. Inspect required checks, mergeability, and actionable review feedback.
3. Fix failures caused by the change, rerun relevant local checks, commit, and push.
4. Repeat until green. After three corrective pushes, or when the same failure survives two evidence-based fixes, reassess the diagnosis.
5. Stop and report when the remaining failure is unrelated, flaky, externally blocked, needs new authority, or would materially expand scope. Do not change unrelated code merely to make CI green.

Green means required local validation passed, required remote checks passed, the branch is mergeable, no actionable review item remains, and the final diff still matches scope.

Immediately before an allowed merge, resolve and run `scripts/check-pr.sh` from this skill directory; do not assume it is relative to the repository. Do not merge if it fails. This preflight verifies that local `HEAD` matches the PR, the PR is ready, GitHub reports it mergeable, and reported checks are green; it does not replace local tests, risk classification, review requirements, or repository protection.

## delivery tier

Classify and state the tier before changing draft state or merging.

- **Small and safe:** narrow, directly requested, easy to review and roll back, with no sensitive-system impact. May mark ready and merge after proportional local validation and required checks pass.
- **Riskier but bounded:** touches several components or important behavior but remains reviewable and reversible. May merge only after broader relevant tests, every required check green, current-base mergeability, and final diff review.
- **Large or high-risk:** large feature; migration; authentication or authorization; billing; security-sensitive behavior; infrastructure or deployment; public API; major dependency upgrade; data-loss risk; or difficult rollback. Keep as a draft PR unless the user explicitly asks to merge.

An explicit `do not merge` always wins. If risk is genuinely ambiguous, leave a green draft rather than guessing downward. Respect repository approvals, branch protection, and merge queues.
