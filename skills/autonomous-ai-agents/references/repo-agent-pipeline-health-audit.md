# Repo-Agent Pipeline Health Audit

Use this when Semyon asks whether the repo-agent full pipeline is working, how it works, or whether it is operating at the intended level.

## Goal

Return an operator verdict, not just a description of the cron prompt. Separate:

- **scheduler health**: job enabled, last status, next run, delivery target
- **pipeline safety**: run mutex, dirty checkout boundaries, worktree cleanup, no auto-merge
- **artifact reality**: PRs/issues/branches/checks verified live where practical
- **coverage**: all allowlisted repos scanned, quiet/blocker repos named
- **intended-vs-actual gaps**: features declared in the prompt but not actually exercised

## Evidence chain

1. Inspect the cron job metadata for `repo-agent full pipeline`: schedule, last status/error, enabled toolsets, prompt shape, delivery target, and repeat count.
2. Read the job prompt or stored cron config enough to identify the intended pipeline: allowlist, state root, run lock, worktree path, phases, safety boundaries, and enabled toolsets.
3. Read `/home/semyon/.hermes/repo-agent/reports/latest.json` for the latest concrete run: `repos_scanned`, `metrics`, PRs/issues opened/updated, blockers, quiet repos, worktrees cleaned, and `delegated_scouts`.
4. Check whether `/home/semyon/.hermes/repo-agent/run.lock` exists. No lock after a completed run is good; a fresh lock means active/duplicate run; a stale lock is a blocker to report.
5. Verify high-value PRs with `gh pr view` before saying they are open, draft, clean, merged, or green. Summaries can be stale.
6. Check `gh auth status` for missing scopes when Project sync is part of the intended pipeline. Missing `project` / `read:project` means GitHub Projects sync is degraded, not the whole repo-agent.
7. Reconcile the verdict: “working”, “working but degraded”, or “not working”, with the exact degraded subsystem.

## Health indicators

Good signs:

- cron job enabled and last status `ok`
- no stale run lock
- latest report parses and is recent
- all allowlisted repos have repo cards or explicit hard blockers
- draft PRs exist and `gh pr view` confirms state/checks
- dirty normal checkouts were avoided via clean worktrees
- disposable worktrees were cleaned only after PR/branch verification

Degraded-but-not-fatal signs:

- `delegated_scouts: 0` despite `delegation` being enabled and prompt requiring fanout. Report this as underuse of parallel scouting/context isolation, not as total failure.
- GitHub Project sync skipped because `gh` lacks `project` / `read:project` scopes. Give the exact human command: `gh auth refresh -h github.com -s project -s read:project`.
- quiet repos have safety reasons such as live API risk, private DBs, binary corpora, or low-touch content decisions.
- many draft PRs are awaiting human review; the bottleneck is merge/review throughput rather than agent execution.

Bad signs:

- cron disabled or repeated non-OK last status
- stale run lock with no active process
- latest report missing/invalid/stale relative to last run
- claims of PR/check success not verifiable in GitHub
- dirty user checkout edited directly
- direct pushes to protected/shared branches
- mutation without an agent worktree/branch
- auto-merge or merge-to-main without explicit approval

## Reporting style

Start with a blunt verdict:

```text
Yes — it is running and producing real draft PRs. But it is degraded: Project sync is blocked by gh scopes and delegated scouting is not actually being used in the latest report.
```

Then give concise sections:

1. Job identity/schedule.
2. Intended pipeline shape.
3. Latest concrete run results.
4. Verified current PR queue.
5. Blockers/degraded features.
6. Operator assessment and next fix.

Avoid burying Semyon in the full cron prompt unless he asks. He wants the operational answer first, with handles and evidence.

## Pitfalls

- Do not call a pipeline “fully working” just because the cron last status is `ok`; compare intended phases against latest metrics.
- Do not call a pipeline “broken” just because Project sync lacks scopes; issues/PRs/Kanban may still work.
- Do not trust `latest.json` alone for PR state; verify with GitHub before reporting current state.
- Do not treat CodeRabbit absent/skipped as a blocking check unless the repo policy says so.
- Do not let `delegation` being enabled in cron config imply it was used; check reported metrics or run transcript evidence.
