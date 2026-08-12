# OpenClaw-style persona teams in Hermes

Use this reference when comparing or migrating an OpenClaw multi-persona setup into Hermes.

## OpenClaw pattern observed

OpenClaw treated personas as first-class agents:

- A top-level config listed agents by `id`, `name`, and `workspace`.
- Each persona had its own workspace and prompt files, commonly:
  - `IDENTITY.md` — name, role, vibe, emoji/avatar.
  - `SOUL.md` — voice, boundaries, behavioural truths.
  - `AGENTS.md` — responsibilities, modes, handoffs.
  - `memory/` — persona-specific memory.
- Gateway bindings routed platform/channel IDs directly to an `agentId`.
- Typical usage patterns were:
  1. direct spawn of a named agent,
  2. main-session auto-routing by agent name/task type,
  3. dedicated Discord/WhatsApp channels with persistent persona context.

Example role split from the migration conversation:

- Camille — chief of staff, planning, admin, priorities.
- Theo — senior developer, code review, architecture, debugging.
- Chuck — network/infra/homelab/DNS/reverse proxy.
- R2D2 — monitoring sentinel, alerts, uptime, disk/certs/backups.
- Eidhne — casual best-mate mode, morale, message vibe checks, practical advice.

## Hermes equivalents

Hermes is less persona-native by default but has stronger infrastructure pieces:

- **Profiles** for strong isolation: independent config, sessions, skills, and memory.
- **Skills** for persona/task instructions that can be loaded into a normal session.
- **Discord/Slack `channel_skill_bindings`** for auto-loading one or more skills at session start for a channel/thread.
- **Discord/Telegram/etc `channel_prompts`** for lightweight per-channel ephemeral system prompts.
- **Cron jobs** for R2D2-style scheduled patrols and briefings.
- **Kanban/delegation** for durable multi-agent work queues and subagent orchestration.

## Migration approach

Prefer this order unless the user explicitly wants full profile isolation:

1. Convert each OpenClaw persona folder into a Hermes skill at class/persona level, preserving useful `IDENTITY`, `SOUL`, and `AGENTS` content in `SKILL.md`.
2. Put bulky persona detail or source excerpts in the skill's `references/` directory instead of bloating the main prompt.
3. Add Discord `channel_skill_bindings` from channel ID to the relevant persona skill.
4. Add `channel_prompts` only for small channel-specific constraints or tone. Do not duplicate entire persona docs there.
5. Use Hermes profiles only when the persona needs separate memory/config/model/toolsets, not merely a different voice.
6. Recreate monitoring/briefing agents as cron jobs, optionally loading the R2D2/Camille skill.

## Comparison rule of thumb

- OpenClaw: “named agent team” is the primary abstraction.
- Hermes: “profiles + skills + gateway bindings + cron/kanban” are the abstractions; the agent team is assembled from them.

When reporting this to the user, make the distinction plainly and avoid pretending Hermes already has OpenClaw's persona routing unless `channel_skill_bindings`, profiles, or prompts are actually configured.