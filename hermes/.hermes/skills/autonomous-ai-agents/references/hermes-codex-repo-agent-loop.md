# Hermes + Codex Repo-Agent Loop

Use this reference when building a recurring local repo-maintenance loop where Hermes wakes on a schedule and Codex/Claude do bounded coding/review tasks.

## Architecture

- **Hermes**: scheduler/orchestrator, repo allowlist, GitHub state transitions, safety policy, final reporting.
- **Codex**: default disposable worker for focused review/implementation threads.
- **Claude Code**: optional independent second-opinion reviewer/planner for high-risk or ambiguous changes.
- **GitHub**: durable state via issues, PRs, labels, comments, branches.
- **Git worktrees**: filesystem isolation for implementation branches.

Do not run one giant mixed-context agent across all repos. Treat every repo and stage independently and pass compact task cards only.

## Staged pipeline

1. **GitHub checker / repo state**
   - Hermes + `git`/`gh`.
   - Read-only except `git fetch --all --prune`.
   - Capture branch, origin, dirty state, open PRs/issues, existing agent branches, recent activity.

2. **Issue finder / PR reviewer**
   - Fresh focused Codex review where useful.
   - For diffs, trace changed files 1-2 layers into callers, callees, importers, tests, config, and data flow.
   - Create issues/comments only when evidence-backed and actionable.

3. **Planning**
   - Fresh focused context.
   - Input: task card only, not transcript.
   - Decide implement/block/split.
   - Output: branch name, worktree path, likely files, checks, risks, stop conditions.

4. **Implementation**
   - Fresh `codex exec` in isolated worktree.
   - Branch names: `agent/fix-...`, `agent/feature-...`, `agent/chore-...`, `agent/polish-...`.
   - Keep changes minimal and reviewable.
   - Commit only intended files.

5. **Review / verification**
   - Fresh context, not the implementer's context.
   - Run safe checks and `codex review --base <base>` or local diff inspection.
   - For high-risk/ambiguous changes, spawn Claude in read-only/planning mode for second opinion.
   - If pass: push only `agent/*`, open/update draft PR, mark awaiting maintainer review.
   - If fail: pass a failure task card back to planning once; then block/report if still failing.

6. **Reporting**
   - Hermes sends a compact digest: issues opened, comments posted, branches pushed, draft PRs, blockers, quiet repos.

## Handoff task card

Pass this shape between stages instead of raw transcripts:

```md
# Task Card

## Repo
- Local: `/path/to/repo`
- GitHub: `owner/repo`
- Base: `main` or `dev`
- Worktree: `/path/to/worktree`
- Branch: `agent/...`

## Target
- Issue: #N
- PR: #N

## Goal
One concise goal statement.

## Previous approach
- 3-8 bullets max describing what was tried.

## Evidence
- Failing command/result, static trace, or review finding.

## Changed / affected files
- `src/foo.ts`

## Checks run
- `npm test -- foo`: pass/fail summary

## Constraints
- No merge.
- Push only `agent/*`.
- Avoid live/API/destructive commands unless explicitly approved.

## Decision needed
Implement, re-plan, block, or request maintainer input.
```

## Claude second opinion

Use Claude only when it adds signal:

- Codex review and local evidence disagree.
- Change touches auth, data integrity, migrations, security, API contracts, build/deploy config, or broad architecture.
- Diff is large enough that same-model self-review is suspect.
- Verification failed twice or failure is ambiguous.
- Before marking a non-trivial PR ready.

Example shape:

```bash
claude -p \
  --permission-mode plan \
  --allowedTools "Read,Grep,Glob,Bash(git *),Bash(npm test),Bash(npm run build),Bash(npm run typecheck)" \
  "Independent second-opinion review. Given this task card and repo, inspect only what is needed. Find concrete correctness/security/test/integration risks. Do not edit files. Return pass/fail and evidence."
```

## Safety rules

Allowed:

- inspect repos, fetch, run safe checks
- create issues/comments when concrete
- create worktrees and `agent/*` branches
- push `agent/*` branches
- open/update draft PRs

Forbidden:

- merge PRs
- push directly to `main`, `dev`, `master`, or `release`
- force-push non-agent branches
- touch ignored repos
- destructive commands
- live/API actions without explicit approval
- vague cleanup issues

## Voice for GitHub comments/PR bodies

Do not sign comments or PR bodies with the maintainer's name. GitHub already shows account identity. Use neutral mechanical phrases like `repo-agent validation`, `repo-agent note`, and `awaiting maintainer review/merge`.
