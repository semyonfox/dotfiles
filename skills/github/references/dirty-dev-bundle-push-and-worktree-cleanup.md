# Dirty dev bundle push and worktree cleanup

Use when Semyon asks whether accumulated local work has been committed/pushed to an integration branch such as `dev`, especially in a repo with many agent worktrees.

## Safe sequence

1. Inspect live state first:
   - `git status --branch --short`
   - `git log --oneline --decorate --max-count=5`
   - `git fetch origin <branch> --prune`
   - classify: local commits ahead, remote commits behind, tracked modifications, untracked files.
2. Create a temporary safety branch before risky integration:
   - `git branch backup/<branch>-before-bundle-$(date +%Y%m%d-%H%M%S)`
3. Stage deliberately. For broad user-approved bundle commits, `git ls-files --modified --others --exclude-standard -z | xargs -0 git add --` is acceptable, but run a staged secret scan before committing.
4. Verify locally before push:
   - `npm run test:ci`
   - `npm run build`
   - if hooks run extra checks, let them run; distinguish real failures from warnings such as unsupported Docker dry-run or missing shellcheck.
5. If the branch is behind remote, rebase before pushing unless the repo policy says otherwise.

## Rebase conflict policy for active dev branches

When rebasing dirty local bundle work onto a newer `origin/dev`, prefer the newer remote architecture when conflicts indicate the remote already landed a replacement. Example pattern from OghmaNotes:

- `origin/dev` had moved from old `SourceEditor`/Source-Read split to the new `WriteEditor` surface.
- Local bundle still modified `source-editor.tsx`.
- Resolution: keep the new `WriteEditor` stack, remove stale `source-editor.tsx`, and port only compatible settings/width behavior to the current editor surface.

Do not blindly choose `--theirs`/`--ours` for all files. For conflict-heavy bundle commits:

- Preserve newly added docs/scripts/tests/features that are not superseded.
- Keep current remote versions for files whose architecture has advanced.
- Port small useful behavior into the new architecture instead of resurrecting deleted files.
- Re-run full tests and build after resolving; do not push until both pass or the blocker is explicitly reported.

## Post-push verification

After `git push origin <branch>`:

1. Verify exact local and remote SHA:
   - `git rev-parse HEAD`
   - `git ls-remote --heads origin <branch>`
2. If Jenkins/deploy is triggered by push, poll a live endpoint that proves the new build is serving. For content-negotiation/route changes, test the actual route and expected content type/body, not just `/api/health`.
3. Only delete the temporary backup branch after remote SHA and live deploy are verified.

## Worktree cleanup policy

1. `git worktree list --porcelain`
2. For each worktree, inspect status from inside it:
   - `git -C <path> status --short --branch`
3. Remove only clean/stale worktrees or detached scratch worktrees whose generated changes are safe to restore.
4. Do **not** remove dirty worktrees silently. Report them as left in place, even if stale.
5. If branch deletion fails because a worktree owns it, remove the worktree first, then prune:
   - `git worktree remove <path>`
   - `git worktree prune`

## Temporary auth/test artifacts

If the work involved throwaway auth users or token files:

- Verify cleanup in all affected DBs/environments with a count query returning `0`.
- Remove `/tmp` credential/token/script files.
- Never print token/password values in the final report.
