# Repo-agent run mutex and blocker triage

Use this when a scheduled repo-agent loop reports `ok` but produces duplicate issues/cards, overlapping digests, or confusing blocker output.

## Duplicate-run symptom

A Hermes cron job can be triggered manually or by the scheduler close enough together that two independent cron sessions run the same job. Both may complete successfully while racing on GitHub issues, Kanban cards, and `latest.json`.

Common evidence:

- agent logs show two `cron_<job_id>_<timestamp>` sessions for the same job within seconds/minutes
- duplicate GitHub issues/cards appear, followed by one being closed as a duplicate
- two cron output markdown files exist for the same run window
- final reports disagree because both sessions wrote `latest.json`

## Fix pattern: top-level run mutex

Add a run-level lock before any pipeline work starts:

```bash
lockdir="$HOME/.hermes/repo-agent/run.lock"
if mkdir "$lockdir" 2>/dev/null; then
  printf '{"pid":%s,"started_at":"%s","session":"%s"}\n' \
    "$$" "$(date -Is)" "${HERMES_SESSION_ID:-unknown}" > "$lockdir/meta.json"
  trap 'rm -rf "$lockdir"' EXIT INT TERM
else
  # If fresh, another run is active. For cron: final response should be [SILENT].
  # If stale, verify no matching process is active before removing.
  exit 0
fi
```

Recommended stale threshold: ~45 minutes for repo-agent sweeps unless the job is known to run longer. Store enough metadata to diagnose abandoned locks.

This is separate from per-repo locks:

- **run mutex**: prevents duplicate whole-pipeline execution
- **repo locks**: serialize mutation of one repo while allowing read-only scouting elsewhere

## Blocker triage lessons

Dirty normal checkouts should not automatically block the whole repo-agent. Treat them as:

- `local user work avoided; isolated worktree used` when safe work can start from `origin/<base>`
- `blocked` only when the selected candidate depends on dirty files, repo metadata is unusable, a fresh lock exists, or project policy forbids action

Existing draft repo-agent PRs are also not a repo-wide stop sign. Inspect/update them first, deduplicate by goal/branch/issue, then allow additional non-overlapping work when clearly scoped and safe.

## GitHub Projects sync scope

If GitHub Projects v2 sync is desired, `gh` needs `project` and `read:project` scopes. Missing scopes should skip only project sync, not issues/PRs/Kanban:

```bash
gh auth refresh -h github.com -s project -s read:project
```

If this starts device-code auth and no user is present, record a human-action blocker rather than failing the repo-agent sweep.
