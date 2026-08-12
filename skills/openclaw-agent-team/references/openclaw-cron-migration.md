# OpenClaw Cron Migration to Hermes

Use this when migrating OpenClaw proactive jobs/heartbeats into Hermes cron.

## What to preserve

OpenClaw had two related concepts:

- **Heartbeat prompts**: low-precision periodic checks that batch several possible concerns and should stay quiet unless something needs attention.
- **Cron jobs**: precise scheduled standalone tasks such as morning briefings or reminders.

In Hermes, model these explicitly:

- Use a **script-only `no_agent=True` cron** for watchdog checks that should be silent when healthy. The script prints only alerts; empty stdout means no delivery.
- Use an **LLM cron job** for briefing/report tasks that need synthesis, prioritization, or natural-language output.

## Discovery workflow

1. Search current Hermes backups/imports first:
   - `~/.hermes/backups/`
   - `~/.hermes/imported-openclaw-workspace/`
   - `~/.hermes/cron/`
2. If old OpenClaw source paths are gone, use session history only as evidence, not as exact job definitions.
3. Look for:
   - `cron/jobs-state.json`
   - `cron/runs/*.jsonl`
   - OpenClaw workspace `AGENTS.md` heartbeat section
   - references to `HEARTBEAT.md`
4. Do not recreate jobs solely from vague memory. If the exact job config is missing, rebuild a Hermes-native equivalent and say so.

## Safe migration pattern

### Monitoring/watchdog jobs

Prefer script-only cron:

```python
cronjob(
    action="create",
    name="R2D2 system watchdog",
    schedule="every 30m",
    deliver="origin",
    script="r2d2_system_watchdog.py",
    no_agent=True,
    prompt="Script-only watchdog. Ignored because no_agent=true.",
)
```

Script rules:

- Exit 0 when healthy.
- Print nothing when healthy.
- Print a short alert summary only when something needs attention.
- Check stable local signals such as disk, memory, load, mounts, Docker health, certs, or backup markers.
- Avoid expensive API/model calls for routine health checks.

### Briefing jobs

Use an LLM cron with a self-contained prompt:

- Include audience, timezone, delivery expectations, and standing priorities.
- Require the cron run to use tools for live facts such as date/time and system state.
- Explicitly forbid pretending to check unavailable sources like email/calendar/social accounts.
- Keep output short and actionable.
- Use `enabled_toolsets` to reduce prompt/tool footprint.

Example schedule:

```python
cronjob(
    action="create",
    name="OpenClaw-style daily morning briefing",
    schedule="0 8 * * *",
    deliver="origin",
    skills=["openclaw-agent-team"],
    enabled_toolsets=["terminal", "file", "session_search"],
    prompt="...self-contained briefing prompt...",
)
```

## Pitfalls

- **Do not blindly resurrect stale OpenClaw jobs.** Old jobs may contain expired OAuth, old delivery channel IDs, or failing Discord/Google paths.
- **Do not import secrets from logs.** Redact tokens and avoid storing credential values in skills or memory.
- **Do not make watchdogs chatty.** A heartbeat/watchdog that reports every 30 minutes is noise. Silence is success.
- **Do not claim exact migration if the original `jobs-state.json` is missing.** Call it a Hermes-native replacement or reconstruction.

## Verification

After creating jobs:

1. Run `cronjob(action="list")`.
2. Run `hermes cron list --all` if terminal tools are available.
3. For script-only jobs, run the script manually and verify:
   - exit code 0
   - empty stdout when healthy
4. Confirm `next_run_at`, delivery target, schedule, and mode match the intended behavior.
