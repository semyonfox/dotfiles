---
name: ship-changes
description: Use when the user asks to commit, push, open or update a PR, repair CI, mark ready, or merge. Validate and deliver only the authorised stage and prerequisites.
metadata:
  harnesses: [claude, codex, opencode, cursor, gemini, hermes]
---

# Ship changes

Treat a request to commit, push, open a PR, ship, land, finish, or merge as authority for the named stage and the stages it needs first, not for unrelated external actions.

## prepare

1. Inspect the worktree, current branch, remotes, existing PR, and unrelated changes.
2. Select the first existing remote base: `dev`, `develop`, `testing`, `staging`, `main`, `master`, then the remote default. An explicitly named base wins.
3. Never implement directly on the base branch. Create or reuse a scoped branch. Use a worktree if switching would disturb the user or another writer.
4. Discover repository-provided format, lint, typecheck, test, and build commands. Run the checks proportionate to the change before committing.
5. Review the staged diff and commit intentionally. Follow the attribution rule in global guidance: none unless the repo opts in.

## pull request

1. Push the scoped branch and open or update the PR against the selected base with the `file-pr` skill. Large or high-risk work starts as a draft.
2. For "repair CI", "make it green", "mark ready" or "merge", get the PR there with `babysit-pr`. Stop and report when the remaining failure is unrelated, flaky, externally blocked, needs new authority, or would materially expand scope. Do not change unrelated code merely to make CI green.

## merging

Merge only when the user asked for it. Use the merge gate in `full-send` as the readiness check. Immediately before merging, run `scripts/check-pr.sh` from this skill's directory, not the repository's, and do not merge if it fails. It checks that local `HEAD` matches the PR, the PR is ready, GitHub reports it mergeable, and reported checks are green. It does not replace the merge gate, the delivery tier, or repository protection.

## delivery tier

Classify and state the tier before changing draft state or merging.

- **Small and safe:** narrow, directly requested, easy to review and roll back, with no sensitive-system impact. May mark ready and merge after proportional local validation and required checks pass.
- **Riskier but bounded:** touches several components or important behavior but remains reviewable and reversible. May merge only after broader relevant tests, every required check green, current-base mergeability, and final diff review.
- **Large or high-risk:** a large feature, migration, authentication or authorisation, billing, security-sensitive behaviour, infrastructure or deployment, public API, major dependency upgrade, data-loss risk, or difficult rollback. Keep as a draft PR unless the user explicitly asks to merge.

An explicit `do not merge` always wins. If risk is genuinely ambiguous, leave a green draft rather than guessing downward. Respect repository approvals, branch protection, and merge queues.
