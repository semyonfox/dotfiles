# Repo-agent cron fan-out pattern

Use this when a scheduled maintainer/repo-agent job is underperforming by touching only one repo or producing one tiny PR per run.

## Symptom

A cron prompt says it is a "full workflow" but the actual runs behave like a timid single-task agent:

- one repo or one PR per run,
- no result card for quiet repos,
- sequential inspection only,
- no subagent/delegation fan-out,
- final digest hides skipped repos.

## Durable fix

Treat this as a control-plane problem, not just a stronger wording problem.

1. Ensure the cron job has the `delegation` toolset enabled, not only `terminal`/`file`/`session_search`.
2. Raise delegation capacity if the workflow genuinely needs parallel repo workers:
   - `hermes config set delegation.max_concurrent_children 6`
   - `hermes config set delegation.child_timeout_seconds 1200`
3. Rewrite the cron prompt to require fan-out explicitly:
   - full allowlist sweep every run,
   - one repo per worker/subagent,
   - parallel waves until every repo has a result card,
   - no early stop after the first success,
   - quiet repos still scanned and reported,
   - parent/orchestrator writes a complete JSON report.
4. Keep mutations conservative:
   - one safe scoped implementation per repo worker,
   - isolated worktree and `agent/*` branch,
   - draft PR only,
   - no merges or protected-branch pushes.

## Prompt language that works

Use direct operating posture language, for example:

> NEW OPERATING POSTURE: FAN-OUT, NOT DRIBBLE. Every run MUST touch every allowlisted repo with at least a state scan/review pass. Use subagents/delegation in parallel waves. Target 4-6 concurrent repo workers when available. Continue waves until every repo has a result card. No early final answer after the first success.

For Semyon's preferred max-spread mode, make it stronger:

> MAX FAN-OUT OPERATING POSTURE: parent cron agent is an orchestrator/reducer only. Every allowlisted repo gets its own repo worker/subagent every run. Inside each repo, split work into focused task subagents where useful: scout/state, PR review, candidate selection, planning, implementation/worktree execution, test verification, Opus review, and cleanup. Pass compact JSON batons/cards only; do not pass full prompt history, cross-repo transcripts, diffs, or logs. No early stop after the first success. If delegation capacity degrades, continue in smaller parallel waves and report `delegated_repo_workers`, `delegated_task_workers`, and `fanout_degraded_reason`.

Then define the mandatory algorithm:

1. Build the full allowlist.
2. Run parent preflight and acquire the run mutex.
3. Launch one repo worker per allowlisted repo in parallel waves.
4. Repo workers launch focused task subagents when useful and return compact repo cards only.
5. Collect compact JSON cards.
6. Verify high-impact outputs.
7. Write `latest.json` with all repo cards and fan-out metrics.
8. Deliver digest grouped by shipped PRs, issues/comments, blockers, quiet scanned repos, and next targets.

When a repo has a duplicate/canonical checkout situation, encode the chosen canonical path in the cron prompt instead of letting future runs rediscover a missing path as a blocker. Example from Semyon's setup: use `/home/semyon/code/university/ct216-software-eng/oghmanotes` as the canonical OghmaNotes checkout mapped to `semyonfox/oghma`; do not treat missing `/home/semyon/code/university/oghma` as a blocker once the duplicate is intentionally selected.

## Pitfall

Phrases like "low-volume" and "one correct draft PR is better than five noisy ones" are sensible safety language, but in a cron scheduler they can accidentally train the agent to stop after one tiny thing. Replace them with: aggressive coverage, conservative mutations.