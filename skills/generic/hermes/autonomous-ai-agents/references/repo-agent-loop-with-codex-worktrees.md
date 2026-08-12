# Repo-agent loop with Codex threads and git worktrees

Use this pattern when Semyon wants recurring low-volume maintenance across several personal repositories without inter-repo context rot.

## Architecture

- **Hermes is the scheduler/orchestrator.** Use Hermes cron for wakeups, delivery, memory/policy, and GitHub/git command control.
- **Codex is the bounded worker.** Spawn Codex `exec` / `review` sessions for focused per-repo or per-task work.
- **GitHub is durable state.** Issues, PRs, labels, branches, comments, and checks are the durable workflow record; model context is disposable.
- **Git worktrees isolate filesystem state.** Use one worktree per implementation branch under a central ignored worktree root such as `~/code/.worktrees/<repo>/<branch-name>`.
- **Dirty normal checkouts are not stop signs.** If the user's main checkout is dirty, treat it as read-only and create a clean isolated worktree from the last remote/base commit (`origin/<base>`), then do all mutation on an `agent/*` branch there. Block only when the selected task depends on the uncommitted files, repo metadata/remotes are unusable, no safe remote base exists, or policy forbids the action.
- **Structured summaries isolate context.** Parent orchestrators receive compact pass/fail/blocked summaries and handles, not full child transcripts or cross-repo code context.

## Recommended layers

1. **Global Hermes scheduler**
   - Knows repo allowlist and policy only.
   - Runs every ~5 hours or another subscription-friendly cadence.
   - Spawns/executes one repo job per active repo.
   - Produces one concise digest for the user.
   - Does not deeply read code or implement changes.

2. **Per-repo orchestrator**
   - Operates on exactly one repo.
   - Fetches GitHub state, lists PRs/issues, checks branch/dirty state.
   - Spawns focused review/implementation/verification threads.
   - Aggregates child summaries and updates GitHub only when allowed.

3. **Focused review thread**
   - Reviews one PR/diff/branch.
   - Traces changed code one or two layers into callers, callees, config, tests, and data flow.
   - Returns concrete findings only.

4. **Implementation thread**
   - Works in one worktree on one issue/feature.
   - Produces a minimal patch, runs relevant checks, commits/pushes only according to policy.
   - Opens or updates a draft PR; never merges.

5. **Verification thread**
   - Separate from implementer when quality matters.
   - Reviews final diff and test output.
   - Returns `ready_for_user_review`, `needs_iteration`, or `blocked`.

## Handoff shape

Pass handles and small JSON, not prose dumps:

```json
{
  "repo": "semyonfox/swim",
  "local_repo": "/home/semyon/code/personal/swim",
  "worktree": "/home/semyon/code/.worktrees/swim/agent-fix-meet-parser",
  "kind": "review",
  "target": {"type": "pr", "number": 18, "base": "dev"},
  "verdict": "changes_requested",
  "actions_taken": ["checked out PR", "ran targeted tests", "traced callers"],
  "tests": [{"command": "npm test -- meetParser", "status": "failed", "summary": "DST boundary fixture fails"}],
  "next_action": "implementation_thread",
  "blocked": false,
  "reason": null
}
```

## Safe rollout phases

1. **Monitor only**: inspect curated repos, fetch/list GitHub state, report deltas. No comments, branches, Codex workers, pushes, or issue creation.
2. **Review/comment**: allow concrete PR comments and actionable issue creation.
3. **Implementation**: allow selected or labelled safe-small-fix issues to spawn worktrees and draft PRs.
4. **Semi-autonomous**: allow small safe fixes and test-gap PRs, still with no auto-merge.

## Safety policy

Agents may:

- fetch/read repo and GitHub state
- run safe checks/tests
- create worktrees
- create/push `agent/*` branches
- open draft PRs
- comment concrete findings
- open specific actionable issues

Agents must not:

- merge PRs
- push to `main`/`dev`
- force-push non-agent branches
- close issues as fixed without merged PR evidence
- run live/destructive API actions without approval
- open vague cleanup issues
- touch ignored repos

## Codex CLI primitives

- `codex exec -C <worktree> --sandbox workspace-write --ask-for-approval never ...` for bounded implementation in an isolated worktree.
- `codex review --base <branch> ...` for review-only passes.
- `codex resume <session-id>` only for continuing the same task.
- `codex fork <session-id>` for trying alternate approaches.
- Prefer fresh threads for new repos, PR updates, issue discovery, and final verification to avoid context rot.

## Common pitfall

Do not let a single global Codex/Hermes thread read every repo and then implement across all of them. That creates cross-repo context rot. Keep global scheduling thin, per-repo context isolated, and task context disposable.