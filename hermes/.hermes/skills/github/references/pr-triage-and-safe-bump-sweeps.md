# PR triage and safe dependency-bump sweeps

Use this when Semyon asks to clear obvious PRs/bump PRs, but still wants conservative judgement.

## One-at-a-time PR review format

For interactive triage, inspect exactly one PR and report:

1. `repo #PR: MERGE` or `HOLD`
2. What it changes, in concrete file/behavior terms
3. Checks/merge state/draft status
4. Risk caveat, especially auth/API/security or weird non-bump files
5. One clear next action: merge or hold

Do not dump the whole queue unless explicitly asked. If the user says "PR by PR", stop after one verdict.

## Safe bump sweep rule

A dependency bump is usually safe to merge when all are true:

- PR is not draft.
- `mergeStateStatus` is `CLEAN`.
- No failing required/app checks; advisory bot-only status can be noted but should not block.
- Diff is package manifest/lockfile only, or clearly isolated dependency metadata.
- The changed path is real project code, not imported raw session dumps, archives, generated device snapshots, or other repository junk.
- No unrelated source/test changes are bundled into the dependabot branch.

For bulk Dependabot sweeps, keep looping after each merge until a fresh global search returns no Dependabot-like PRs. Dependabot may open follow-up PRs within seconds after an older bump lands, and GitHub may briefly report `UNKNOWN`/`UNSTABLE` while mergeability and checks recompute. Re-read each candidate before merging; wait for real checks to settle rather than trusting the first inventory.

## Hold conditions

Hold instead of merging when any apply:

- `DIRTY`, `UNKNOWN`, or conflicted merge state after recent merges.
- Draft PR unless the user explicitly approves marking ready and the diff/checks are trivial.
- Missing real checks for auth/security/API behavior changes.
- Dependency PR includes unrelated source/test changes; inspect separately before merge.
- Dependency PR targets an unexpected base branch compared with the repo's flow.
- PR lives under dumped/session/device paths rather than maintained project directories.
- Failing app/DB/e2e checks, even if other checks are green.

## Stale/superseded bump cleanup

When a Dependabot PR is old and conflicted, do not blindly rebase it. First inspect current `main`/base:

- If current base already carries a newer/equivalent dependency state, close the stale PR as superseded and delete the Dependabot branch when possible.
- If the PR targets archived session/device-dump paths that no longer exist on current base, close it as obsolete rather than recreating archive junk just to satisfy the bot.
- If the path is a real maintained project and current base does not include the bump, either wait for Dependabot to regenerate a clean PR after related merges, or create a small fresh rollup PR with native lockfile regeneration and project checks.

After closing or merging stale bumps, run the global Dependabot search again; bot queues often cascade.

## Useful gh inspection commands

```bash
gh search prs --owner semyonfox --state open --limit 100 \
  --json repository,number,title,author,isDraft,updatedAt,url

gh pr view <n> --repo owner/repo \
  --json number,title,state,isDraft,mergeStateStatus,baseRefName,headRefName,author,additions,deletions,changedFiles,files,statusCheckRollup,url

gh pr diff <n> --repo owner/repo --patch --color never

gh pr checks <n> --repo owner/repo --watch=false
```
