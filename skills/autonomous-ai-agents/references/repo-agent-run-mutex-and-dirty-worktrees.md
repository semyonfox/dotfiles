# Repo-agent run mutex and dirty-checkout worktree escape hatch

Use this when debugging or improving recurring repo-agent cron jobs that scan/mutate multiple repositories.

## Lessons

### 1. Add a top-level run mutex for recurring repo-agent cron jobs

Hermes cron/manual triggers can overlap closely enough that two repo-agent sessions may run at once. That can create duplicate GitHub issues, duplicate Kanban cards, or two agents racing on the same repo.

Use a run-level mutex before any repo scan, delegation, GitHub mutation, issue creation, Kanban update, or report write:

```bash
lockdir=/home/semyon/.hermes/repo-agent/run.lock
if mkdir "$lockdir"; then
  printf '{"pid":%s,"started_at":"%s"}\n' "$$" "$(date -Is)" > "$lockdir/meta.json"
  trap 'rm -rf "$lockdir"' EXIT
else
  # If fresh, exit silently. If stale, verify no matching active process before recovery.
  exit 0
fi
```

Recommended behaviour:
- Fresh lock: return `[SILENT]` for cron delivery unless lock metadata itself needs human attention.
- Stale lock: only recover after checking no matching active Hermes/cron process is still running; record recovery in the report.
- Keep this separate from per-repo mutation locks.

### 2. Dirty normal checkouts should not be blanket blockers

A dirty main checkout means: do not touch that checkout. It does **not** mean: do no work in that repo.

Default escape hatch:

```bash
git -C "$repo" fetch --prune origin
base_branch=<staging|dev|develop|main|master>
slug=<safe-task-slug>
worktree=/home/semyon/code/.worktrees/<repo-name>/$slug
git -C "$repo" worktree add -b "agent/$slug" "$worktree" "origin/$base_branch"
git -C "$worktree" status --porcelain=v1
```

Rules:
- Never edit/reset/clean/stage/commit files in the user's dirty normal checkout.
- Prefer `origin/<base>` over local `HEAD`, because local `HEAD` may include unpushed or user-specific state.
- Verify the worktree is clean and the branch starts with `agent/` before implementation.
- If an existing worktree is dirty, do not auto-clean it; create a new worktree or report that specific worktree as blocked.
- Block only when the selected task depends on uncommitted user files, remotes/base cannot be resolved, repo metadata is unusable, a fresh lock exists, or project policy forbids action.

### 3. Detect local-only issue sources

The clean-worktree path can reveal a real blocker: a GitHub issue may describe files that exist only in the dirty local checkout and not on `origin/<base>`. In that case:

- Do not copy dirty local files into the worktree automatically.
- Comment/update the issue or report that the source is local-only.
- Ask for the local files to be committed/pushed to an agent/user branch, or for explicit local checkout triage approval.
- Clean up empty attempt worktrees/branches after verifying no changes.

## Report language

Prefer:
- `dirty checkout avoided; clean worktree from origin/dev used`
- `blocked: selected issue depends on local-only uncommitted files`

Avoid:
- `dirty checkout blocked repo`
- `no safe work because repo dirty` when a clean origin worktree was possible.
