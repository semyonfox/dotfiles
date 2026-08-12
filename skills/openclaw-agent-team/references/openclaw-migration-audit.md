# OpenClaw → Hermes migration audit notes

Use this reference when migrating an old OpenClaw workspace into Hermes.

## Migration shape that worked

- Back up the original OpenClaw material before editing Hermes state.
- Preserve the raw OpenClaw workspace under `~/.hermes/imported-openclaw-workspace/` rather than flattening everything into memory.
- Convert stable role/persona definitions into Hermes `agent.personalities` entries.
- Convert reusable routing knowledge into a class-level skill (`openclaw-agent-team`) instead of one skill per persona.
- Keep raw `DREAMS.md`/archive material out of durable memory unless it contains stable, factual, still-useful details.
- Add a compact memory only for stable routing facts and archive locations.

## Cron/job migration pitfall

Do not blindly recreate OpenClaw cron jobs in Hermes.

Before porting a job:
1. Inspect recent run history/logs.
2. Identify whether failures are due to stale credentials, expired OAuth tokens, bad delivery targets, or old platform-specific channel IDs.
3. Preserve run history if useful, but only create a live Hermes cron once its data sources and delivery target are valid.
4. Prefer `deliver='origin'`/current Hermes delivery semantics over hard-coded old Discord or WhatsApp channel IDs unless the user explicitly asks for a specific target and it has been verified.

A migrated job that repeatedly failed with Google OAuth expiry and unsupported Discord channel delivery should be archived, not resurrected. Recreating it as-is creates noisy broken automation.