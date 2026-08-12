# jj colocated dirty worktree to GitHub PR

Use this when a repo is already colocated with Jujutsu (`.jj/`) and has useful local dirty work that should become a real GitHub PR.

## Workflow

1. Inspect both surfaces before touching history:

```bash
jj status
jj diff --stat
jj diff --summary
gh pr list --state open --json number,title,isDraft,baseRefName,headRefName,mergeStateStatus,url
```

2. Classify the dirty work:

- source/test/docs/instructions: candidate for commit/PR
- generated artifacts, caches, env files, local DBs, IDE metadata: do not stage without explicit reason
- mixed feature + docs/setup changes: keep together only when they are genuinely part of the same deliverable; otherwise split with jj before pushing

3. Verify the useful change before push. Run the narrow test first, then broader checks appropriate to risk:

```bash
pnpm --filter <workspace> exec vitest run <focused-test>
pnpm --filter <workspace> lint
```

4. Rebase onto the lowest intended integration branch (`dev` when present, otherwise `main`) before opening a PR:

```bash
jj git fetch
jj rebase -r @ -d dev
```

5. Describe and bookmark the change:

```bash
jj describe -m 'fix: concise change summary'
jj bookmark set agent/<short-topic>-$(date +%Y%m%d) -r @
```

6. Secret-scan the diff, then push the bookmark:

```bash
jj diff --git | grep -E -i '(api[_-]?key|secret|password|token|BEGIN (RSA|OPENSSH|PRIVATE)|gho_|github_pat_|sk-[A-Za-z0-9])' || true
jj git push --bookmark agent/<short-topic>-YYYYMMDD --remote origin
```

7. Create a non-draft PR to the lowest branch:

```bash
gh pr create --base dev --head agent/<short-topic>-YYYYMMDD \
  --title 'fix: concise change summary' \
  --body $'## Summary\n- ...\n\n## Checks\n- ...'
```

8. After the PR exists, park the main worktree cleanly back on the base branch so future agents do not see the PR changes as dirty:

```bash
jj new dev
jj status
git status --short --branch
```

The committed change remains on the pushed bookmark/PR; the local working copy becomes clean.

## Draft PR promotion

When asked to make ready drafts that are ready:

1. Query all drafts with `gh search prs --owner <owner> --state open --draft true`.
2. For each, inspect `mergeStateStatus`, checks, base/head, and title with `gh pr view`.
3. Mark ready only when the PR is non-conflicted (`CLEAN`/otherwise mergeable) and has no failing required/real checks.
4. Leave `DIRTY`/conflicted drafts as drafts and report the blocker.
5. After `gh pr ready`, verify `isDraft=false`.
6. If the title still says `draft:` after promotion, edit the title to remove stale draft wording.

Do not promote conflicted drafts just to satisfy a bulk request; readiness includes mergeability.
