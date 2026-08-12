# Repo-agent draft PR unblock sweep

Use this when Semyon asks to "unblock yourself", approve safe repo-agent output, or clear a queue of human-gated draft PRs without breaking anything.

## Pattern

1. Inventory each PR with live GitHub state:
   - `gh pr view <n> -R <owner/repo> --json title,state,isDraft,mergeStateStatus,baseRefName,headRefName,files,commits,body,url`
   - `gh pr checks <n> -R <owner/repo> --json name,state,bucket,link --watch=false`
2. Split candidates by evidence, not by draft status:
   - **Mergeable immediately:** CLEAN plus real CI/checks passing, or comment/docs/test-only deltas with tiny inspectable diffs.
   - **Needs local verification:** body claims tests passed but GitHub only shows bot/advisory/label/CodeQL checks, especially production code, CI gate, or behavior changes.
   - **Hold:** conflicted/DIRTY, product-direction changes, live-data/secrets risk, or broad unverified runtime behavior.
3. If unsure and the user allowed it, ask Claude Code for a concise second-opinion verdict with `claude -p`, but treat it as review input, not proof. Real proof is still diff inspection, CI, or local project checks.
4. For bot-only but plausible candidates, fetch the PR branch into a temporary worktree and run the exact project checks before merging. Install dependencies in the temp worktree if needed; do not treat missing `node_modules` as a PR failure.
5. Promote only after verification:
   - `gh pr ready <n> -R <owner/repo>`
   - remove stale `draft:` wording from the title with `gh pr edit`
   - after marking ready, re-read `mergeStateStatus` and checks. GitHub/bot reviews can temporarily flip a PR from `CLEAN` to `UNSTABLE` while CodeRabbit/GitGuardian/etc. rerun; poll until it returns `CLEAN` or a real failure appears before merging.
   - merge small agent PRs with `gh pr merge <n> --squash --delete-branch`
6. Verify every merge with `gh pr view <n> --json state,mergedAt,mergeCommit,baseRefName,url`.
7. Clean temporary verification worktrees and local `pr-*-verify-*` branches after the sweep.

## Stale duplicate PR salvage

When old human/external PRs conflict with current base but contain a useful small idea:

- Do not resolve the stale branch wholesale if newer repo-agent PRs have already changed the same files.
- Use a throwaway clone/worktree to compare the stale PRs against current base with `git merge-tree`, `git diff --stat`, and file-level diffs.
- Start a fresh `agent/*` branch from current base and port only the residual useful delta, adding or preserving the focused test that proves it.
- Open a replacement draft PR that explicitly supersedes the stale PRs, verify it, then close the old PRs with a superseded-by comment.
- Once bot checks settle and local verification passes, mark the replacement ready and merge if it is small and clean.

## Dirty/local-only blocker salvage

When a repo-agent blocker says the issue depends on files only present in a dirty normal checkout:

- Do **not** copy the whole dirty checkout or commit IDE/user/PDF/data noise.
- Create a clean worktree from `origin/<base>` on an `agent/*` branch.
- Inspect the dirty checkout and copy only the source/config/test files required for the issue.
- Add a small static or non-live test when the issue is security/config related.
- Run `git diff --check`, project syntax/static checks, and a staged secret scan.
- Open a draft PR and move the blocker label/card to "fix ready" rather than merging automatically.

## Pitfalls

- GitHub Project scope refresh (`gh auth refresh -s project -s read:project`) may require an interactive device login. If it times out, report that the blocker remains; do not pretend scopes changed.
- CodeQL/GitGuardian/CodeRabbit can support confidence but do not replace app/build/test checks for runtime changes.
- Shell PR bodies containing backticked filenames can be command-substituted if passed inline. Prefer `--body-file` for PR bodies/comments that mention paths like `.env.example` or `.gitignore`.
