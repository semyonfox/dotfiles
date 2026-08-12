# Repo-Agent Orchestration Pattern

Use this when building a recurring repo-maintenance loop with Hermes/Codex/Claude/OpenCode.

## Core Architecture

- **Hermes is the scheduler/orchestrator**: cron cadence, repo allowlist, ignored repos, GitHub state transitions, final reporting, and safety policy.
- **Codex is the default bounded worker**: focused `codex exec` / `codex review` calls for implementation and review.
- **Claude Code is an optional second-opinion reviewer**: use read-only/planning mode for high-risk or ambiguous changes, not as the default implementer.
- **GitHub is durable state**: issues, PRs, labels, branches, comments, and checks are the system of record.
- **Worktrees are filesystem isolation**: one agent branch/worktree per implementation task.
- **Model context is disposable**: avoid resuming stale global threads; prefer fresh per-task contexts.

## Staged Pipeline

1. **GitHub checker / repo state**
   - Run `git fetch --all --prune`.
   - Inspect branch/origin/dirty state, ahead/behind, open PRs/issues, existing `agent/*` branches/PRs, and recent activity.
   - Output compact repo-state JSON. Do not deep-read multiple repos into one context.

2. **Issue finder / PR reviewer**
   - For PRs, review diffs and trace changed files 1-2 layers deeper into callers, callees, importers, tests, config, and data flow.
   - For issue discovery, only create evidence-backed findings with affected files, risk, suggested direction, and acceptance criteria.

3. **Planning**
   - Input only the task card: selected issue/PR/finding, repo handle, relevant paths, constraints, acceptance criteria, safe commands, and previous approach if any.
   - Decide: implement now, split smaller, or block for user.
   - Produce branch name, worktree path, likely files, checks, risk level, and stop conditions.

4. **Implementation**
   - Create/use worktree under a central root such as `~/code/.worktrees/<repo>/<branch-slug>`.
   - Branch examples: `agent/fix-<issue>-<slug>`, `agent/feature-<slug>`, `agent/chore-<slug>`, `agent/polish-<slug>`.
   - Run Codex only inside the worktree, scoped to the plan:
     ```bash
     codex exec -C "$WORKTREE" \
       --sandbox workspace-write \
       --ask-for-approval never \
       --output-last-message "$WORKTREE/.agent/codex-summary.md" \
       "Implement this exact scoped plan. Keep patch minimal and reviewable. Respect repo conventions. Run relevant safe checks. Do not merge. Do not push main/dev/master. If live/API/destructive actions would be needed, stop and report blocked."
     ```
   - Inspect the diff after Codex. If broad, unsafe, unrelated, or off-plan, block/report instead of pushing.

5. **Review / verification**
   - Use a fresh context, not the implementer's context.
   - Run safe checks outside Codex when possible; pipe concise failures back only if retrying.
   - Use optional Claude second opinion for auth, data integrity, migrations, security, API contracts, build/deploy config, large diffs, ambiguous failures, or non-trivial PR readiness.
   - If pass: push only the `agent/*` branch, open/update a draft PR, and note that the user must approve/merge.
   - If fail: route one compact failure task card back to planning. Retry once if small/clear; otherwise block/report.

6. **Reporting**
   - Send a concise digest: issues opened, comments posted, branches pushed, draft PRs opened/updated, PRs ready for user review, blockers, quiet repos.

## Handoff Task Card

Pass task cards, not transcripts. Normal handoffs should usually be 500-1500 words or less; global summaries should be much smaller.

```md
# Task Card

## Repo
- Local: `/path/to/repo`
- GitHub: `owner/repo`
- Base: `dev`
- Worktree: `/path/to/.worktrees/repo/agent-fix-12-parser`
- Branch: `agent/fix-12-parser`

## Target
- Issue: #12
- PR: #18 if applicable

## Goal
One clear sentence describing the desired outcome.

## Previous approach
- 3-8 bullets max.
- Include what was tried and why it failed if this is a retry.

## Evidence
- Exact test/check result summaries.
- Static trace: affected callers/callees/config/tests/data flow.

## Changed or likely files
- `src/foo.ts`
- `tests/foo.test.ts`

## Checks run
- `npm test -- foo`: failed/pass + one-line reason

## Constraints
- Keep patch minimal.
- Do not merge.
- Push only `agent/*` branch.
- Avoid live/API/destructive actions unless explicitly approved.

## Decision needed
What the receiving agent should decide or do next.
```

## Context Budget Guidelines

- GitHub checker -> issue finder: 100-300 words/repo or JSON handles.
- Issue finder/reviewer -> planner: 500-1000 words.
- Planner -> implementer: 500-1500 words, precise and constraint-heavy.
- Implementer -> verifier: 300-1000 words plus file paths/branch/worktree handles.
- Failed verifier -> planner: 500-1500 words with exact failure evidence and attempted approach.
- Repo orchestrator -> global digest: 50-150 words/repo.

## Second Opinion with Claude Code

Use Claude for independent review, not routine tiny changes:

```bash
claude -p \
  --permission-mode plan \
  --allowedTools "Read,Grep,Glob,Bash(git *),Bash(npm test),Bash(npm run build),Bash(npm run typecheck)" \
  "Independent second-opinion review. Given this task card and repo/worktree path, inspect only what is needed. Find concrete correctness/security/test/integration risks. Do not edit files. Return pass/fail and evidence."
```

Treat Claude output as advisory; Hermes or the orchestrator makes the final state transition.

## Safety Rules

Agents may inspect, fetch, run safe checks, create worktrees, create/push `agent/*` branches, open draft PRs, and post concrete issue/PR comments.

Agents must not merge, push directly to `main`/`dev`/`master`/`release`, force-push user branches, run destructive commands, touch ignored repos, or run live/API/destructive workflows without explicit approval.
