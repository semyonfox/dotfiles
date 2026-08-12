# Repo-Agent Health Check Pattern

Use when Semyon asks whether the repo-agent pipeline is working, what the full pipeline is, or why it appears idle.

## Evidence chain

1. List cron jobs and identify `repo-agent full pipeline`.
2. Read the job prompt/config to capture intended behaviour: allowlist, schedule, loaded skills, enabled toolsets, run mutex, worktree path, report path, and safety posture.
3. Read `/home/semyon/.hermes/repo-agent/reports/latest.json` for observed behaviour.
4. Verify current open PR state with `gh pr view` for named PRs before claiming they are open, clean, draft, merged, or blocked.
5. Check operational prerequisites:
   - no stale `/home/semyon/.hermes/repo-agent/run.lock`
   - `git`, `gh`, `codex`, and optional reviewer CLI availability/auth
   - `gh auth status` includes `project` and `read:project` if Project sync is expected
6. Compare intended phases against observed metrics. Important mismatch examples:
   - cron `last_status: ok` but no useful artifact in latest report
   - `delegation` toolset enabled but report says `delegated_scouts: 0`
   - Project sync configured but skipped for missing scopes
   - dirty checkout listed as blocker even though a clean worktree from `origin/<base>` would be safe
   - many open draft PRs are clean, meaning human review is now the bottleneck, not automation
7. Check **feature utilization** rather than just health: confirm whether cron, loaded skills, enabled toolsets, delegation, Kanban, GitHub Projects, isolated worktrees, reviewer gates, cleanup, and report writing are all actually represented in the latest output/metrics.
8. Check **priority alignment** against Semyon's current project priorities. A pipeline can be technically healthy but strategically weak if it spends cycles on lower-priority repos while OghmaNotes/swim are blocked, missing, dirty, or only scanned read-only. Call this out separately from generic blockers.
9. For priority drift, suggest concrete routing fixes: split into a priority cron for OghmaNotes/swim and a slower background sweep for other repos; increase per-run safe artifact targets; require clean-worktree escape hatches for remote-base tasks; or surface one human-action queue item at a time.

## Reporting shape

Keep it operator-short:

```text
Verdict: working / degraded / blocked.
Working: <real artifacts verified>
Degraded: <configured-vs-observed mismatches>
Blocked: <human action or exact unsafe repo state>
Next: <one or two concrete fixes>
```

## GitHub Project scope repair

If Project sync is the only missing piece, the repair command is:

```bash
gh auth refresh -h github.com -s project -s read:project
```

In a headless session, run it in a PTY/background process, capture the one-time device code, open `https://github.com/login/device` in a browser, complete auth, then re-run `gh auth status` to verify scopes. Do not brute-force or repeatedly guess credentials; if the user's password-manager path is unclear, stop and ask for the exact safe retrieval method.
